import AVFoundation
import Foundation

final class RhythmPlaybackEngine {
    var onStep: (@MainActor (Int) -> Void)?

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let bufferLock = NSLock()
    private let generationLock = NSLock()
    private var voicePools: [InstrumentVoice: VoicePool] = [:]
    private var defaultBuffers: [InstrumentVoice: AVAudioPCMBuffer] = [:]
    private var activeBuffers: [InstrumentVoice: AVAudioPCMBuffer] = [:]
    private var playbackTask: Task<Void, Never>?
    private var playbackGeneration: UInt64 = 0
    private var activeSamplePackID: String?

    init() {
        configureSession()
        configureEngine()
    }

    func play(
        variant: RhythmVariant,
        cycle: RhythmCycle,
        bpm: Double,
        samplePack: RhythmSamplePack?,
        mutedLaneIDs: Set<String>
    ) {
        updateBuffersIfNeeded(for: samplePack)
        let generation = advancePlaybackGeneration()
        playbackTask?.cancel()

        playbackTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var step = 0
            let sanitizedBPM = self.sanitizedBPM(bpm)

            while !Task.isCancelled, self.isCurrentPlaybackGeneration(generation) {
                self.playStep(
                    variant: variant,
                    cycle: cycle,
                    step: step,
                    generation: generation,
                    mutedLaneIDs: mutedLaneIDs
                )

                await MainActor.run {
                    guard self.isCurrentPlaybackGeneration(generation) else { return }
                    self.onStep?(step)
                }

                let duration = cycle.durationPerStep(at: sanitizedBPM)
                let nanoseconds = UInt64(duration * 1_000_000_000)
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    return
                }

                guard self.isCurrentPlaybackGeneration(generation) else { return }

                step = (step + 1) % cycle.stepCount
            }
        }
    }

    func stop() {
        advancePlaybackGeneration()
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func playStep(
        variant: RhythmVariant,
        cycle: RhythmCycle,
        step: Int,
        generation: UInt64,
        mutedLaneIDs: Set<String>
    ) {
        for lane in variant.lanes {
            guard isCurrentPlaybackGeneration(generation), !Task.isCancelled else { return }
            guard !mutedLaneIDs.contains(lane.id) else { continue }
            guard let event = lane.event(at: step) else { continue }

            trigger(voice: lane.voice, intensity: event.intensity)
        }
    }

    private func advancePlaybackGeneration() -> UInt64 {
        generationLock.lock()
        defer { generationLock.unlock() }
        playbackGeneration &+= 1
        return playbackGeneration
    }

    private func isCurrentPlaybackGeneration(_ generation: UInt64) -> Bool {
        generationLock.lock()
        defer { generationLock.unlock() }
        return playbackGeneration == generation
    }

    private func sanitizedBPM(_ bpm: Double) -> Double {
        guard bpm.isFinite, bpm > 0 else {
            return 120
        }
        return bpm
    }

    private func trigger(voice: InstrumentVoice, intensity: Double) {
        guard let pool = voicePools[voice] else { return }
        guard let buffer = activeBuffer(for: voice) else { return }

        let node = pool.nextNode()
        node.volume = Float(intensity)
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        node.play()
    }

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure audio session: \(error)")
        }
        #endif
    }

    private func configureEngine() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        mixer.outputVolume = 0.85

        for voice in InstrumentVoice.allCases {
            defaultBuffers[voice] = makeBuffer(for: voice)

            let pool = VoicePool()
            for _ in 0..<4 {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: mixer, format: format)
                pool.nodes.append(node)
            }
            voicePools[voice] = pool
        }

        activeBuffers = defaultBuffers

        do {
            try engine.start()
        } catch {
            assertionFailure("Failed to start audio engine: \(error)")
        }
    }

    private func activeBuffer(for voice: InstrumentVoice) -> AVAudioPCMBuffer? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return activeBuffers[voice]
    }

    private func updateBuffersIfNeeded(for samplePack: RhythmSamplePack?) {
        let targetPackID = samplePack?.id
        bufferLock.lock()
        let shouldReload = activeSamplePackID != targetPackID
        bufferLock.unlock()
        guard shouldReload else { return }

        var nextBuffers = defaultBuffers
        if let samplePack {
            for (voice, reference) in samplePack.voices {
                if let sampleBuffer = loadSampleBuffer(reference) {
                    nextBuffers[voice] = sampleBuffer
                }
            }
        }

        bufferLock.lock()
        activeBuffers = nextBuffers
        activeSamplePackID = targetPackID
        bufferLock.unlock()
    }

    private func loadSampleBuffer(_ reference: RhythmSampleReference) -> AVAudioPCMBuffer? {
        guard let resourceExtension = reference.resourceExtension else {
            return nil
        }
        guard let url =
            Bundle.main.url(
                forResource: reference.resourceName,
                withExtension: resourceExtension,
                subdirectory: reference.resourceSubdirectory
            ) ??
            Bundle.main.url(
                forResource: reference.resourceName,
                withExtension: resourceExtension
            ) else {
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let sourceFormat = file.processingFormat
            let frameCapacity = AVAudioFrameCount(file.length)
            guard let sourceBuffer = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: frameCapacity
            ) else {
                return nil
            }
            try file.read(into: sourceBuffer)

            if matchesPlaybackFormat(sourceFormat) {
                return sourceBuffer
            }

            return convertBuffer(sourceBuffer, from: sourceFormat)
        } catch {
            assertionFailure("Failed to load sample buffer at \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func convertBuffer(
        _ sourceBuffer: AVAudioPCMBuffer,
        from sourceFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: sourceFormat, to: format) else {
            return nil
        }

        let ratio = format.sampleRate / sourceFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(sourceBuffer.frameLength) * ratio).rounded(.up)) + 512
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: capacity
        ) else {
            return nil
        }

        var didProvideBuffer = false
        var conversionError: NSError?
        let status = converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            if didProvideBuffer {
                outStatus.pointee = .endOfStream
                return nil
            }

            didProvideBuffer = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        if let conversionError {
            assertionFailure("Failed to convert sample buffer: \(conversionError)")
            return nil
        }

        guard status != .error else {
            return nil
        }

        return convertedBuffer
    }

    private func matchesPlaybackFormat(_ sourceFormat: AVAudioFormat) -> Bool {
        sourceFormat.sampleRate == format.sampleRate &&
        sourceFormat.channelCount == format.channelCount &&
        sourceFormat.commonFormat == format.commonFormat &&
        sourceFormat.isInterleaved == format.isInterleaved
    }

    private func makeBuffer(for voice: InstrumentVoice) -> AVAudioPCMBuffer {
        let samples: [Float]

        switch voice {
        case .click:
            samples = makeClick(duration: 0.015, amplitude: 0.45)
        case .kick:
            samples = makeKick(duration: 0.18, baseFrequency: 55, amplitude: 0.95)
        case .snare:
            samples = makeNoiseBurst(duration: 0.11, cutoff: 0.22, amplitude: 0.75, withTone: 210)
        case .closedHat:
            samples = makeNoiseBurst(duration: 0.05, cutoff: 0.82, amplitude: 0.4, withTone: nil)
        case .openHat:
            samples = makeNoiseBurst(duration: 0.16, cutoff: 0.9, amplitude: 0.35, withTone: nil)
        case .shaker:
            samples = makeNoiseBurst(duration: 0.07, cutoff: 0.66, amplitude: 0.28, withTone: nil)
        case .clave:
            samples = makeWoodTone(duration: 0.07, frequency: 1_420, amplitude: 0.6)
        case .bell:
            samples = makeBell(duration: 0.18, frequency: 1_080, amplitude: 0.42)
        case .lowTom:
            samples = makeTom(duration: 0.15, frequency: 110, amplitude: 0.72)
        case .midTom:
            samples = makeTom(duration: 0.14, frequency: 180, amplitude: 0.55)
        }

        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        )!
        buffer.frameLength = buffer.frameCapacity
        let pointer = buffer.floatChannelData![0]
        for (index, sample) in samples.enumerated() {
            pointer[index] = sample
        }
        return buffer
    }

    private func makeKick(duration: Double, baseFrequency: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var phase = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-6.5 * progress)
            let frequency = baseFrequency + (90 * (1 - progress))
            phase += (2 * .pi * frequency) / format.sampleRate
            output[index] = Float(sin(phase) * envelope * amplitude)
        }

        return output
    }

    private func makeTom(duration: Double, frequency: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var phase = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-5.4 * progress)
            phase += (2 * .pi * frequency) / format.sampleRate
            output[index] = Float((sin(phase) + 0.18 * sin(phase * 1.5)) * envelope * amplitude)
        }

        return output
    }

    private func makeClick(duration: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var noise = SeededNoise(seed: 34)

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-20 * progress)
            output[index] = Float(noise.next() * envelope * amplitude)
        }

        return output
    }

    private func makeNoiseBurst(
        duration: Double,
        cutoff: Double,
        amplitude: Double,
        withTone toneFrequency: Double?
    ) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var noise = SeededNoise(seed: UInt64(count) + 17)
        var previous = 0.0
        var phase = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-9.0 * progress)
            let raw = noise.next()
            let filtered = previous + cutoff * (raw - previous)
            previous = filtered

            var sample = filtered
            if let toneFrequency {
                phase += (2 * .pi * toneFrequency) / format.sampleRate
                sample += 0.28 * sin(phase)
            }

            output[index] = Float(sample * envelope * amplitude)
        }

        return output
    }

    private func makeWoodTone(duration: Double, frequency: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var phase = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-12 * progress)
            phase += (2 * .pi * frequency) / format.sampleRate
            let overtone = sin(phase * 1.9) * 0.25
            output[index] = Float((sin(phase) + overtone) * envelope * amplitude)
        }

        return output
    }

    private func makeBell(duration: Double, frequency: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var phase = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-7.0 * progress)
            phase += (2 * .pi * frequency) / format.sampleRate
            let sample =
                sin(phase) +
                0.45 * sin(phase * 1.5) +
                0.22 * sin(phase * 2.1)

            output[index] = Float(sample * envelope * amplitude)
        }

        return output
    }
}

private final class VoicePool {
    var nodes: [AVAudioPlayerNode] = []
    private let lock = NSLock()
    private var index = 0

    func nextNode() -> AVAudioPlayerNode {
        lock.lock()
        defer { lock.unlock() }

        guard !nodes.isEmpty else {
            fatalError("Voice pool must contain at least one node.")
        }

        defer {
            index = (index + 1) % nodes.count
        }

        return nodes[index]
    }
}

private struct SeededNoise {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> Double {
        state = 2862933555777941757 &* state &+ 3_037_000_493
        let normalized = Double(state % 10_000) / 10_000.0
        return (normalized * 2) - 1
    }
}

private extension InstrumentVoice {
    static let allCases: [InstrumentVoice] = [
        .click,
        .kick,
        .snare,
        .closedHat,
        .openHat,
        .shaker,
        .clave,
        .bell,
        .lowTom,
        .midTom
    ]
}
