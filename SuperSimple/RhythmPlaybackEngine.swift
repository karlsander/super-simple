import AVFoundation
import Foundation

final class RhythmPlaybackEngine {
    struct Arrangement {
        let variant: RhythmVariant
        let cycle: RhythmCycle
        let bpm: Double
        let samplePack: RhythmSamplePack?
        let mutedLaneIDs: Set<String>
    }

    var onStep: (@MainActor (Int?) -> Void)?
    var onArrangementApplied: (@MainActor (Arrangement) -> Void)?
    var onPendingStateChange: (@MainActor (Bool) -> Void)?

    private struct RenderedArrangement {
        var arrangement: Arrangement
        let laneBuffers: [LaneRole: AVAudioPCMBuffer]
        let cycleFrameCount: AVAudioFrameCount
        let stepDuration: TimeInterval
        let cycleDurationHostTime: UInt64
    }

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let schedulerQueue = DispatchQueue(
        label: "SuperSimple.RhythmPlaybackEngine",
        qos: .userInteractive
    )
    private let startLeadTime: TimeInterval = 0.06
    private let queueLeadTime: TimeInterval = 0.05
    private let clockInterval: DispatchTimeInterval = .milliseconds(16)

    private var laneNodes: [LaneRole: AVAudioPlayerNode] = [:]
    private var defaultBuffers: [InstrumentVoice: AVAudioPCMBuffer] = [:]
    private var activeBuffers: [InstrumentVoice: AVAudioPCMBuffer] = [:]
    private var activeSamplePackID: String?
    private var currentRenderedArrangement: RenderedArrangement?
    private var desiredRenderedArrangement: RenderedArrangement?
    private var scheduledRenderedArrangement: RenderedArrangement?
    private var cycleStartHostTime: UInt64?
    private var scheduledApplyHostTime: UInt64?
    private var clockTimer: DispatchSourceTimer?
    private var isRunning = false
    private var lastPublishedStep: Int?
    private var lastPublishedPendingState = false

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
        start(
            arrangement: Arrangement(
                variant: variant,
                cycle: cycle,
                bpm: bpm,
                samplePack: samplePack,
                mutedLaneIDs: mutedLaneIDs
            )
        )
    }

    func start(arrangement: Arrangement) {
        schedulerQueue.async {
            self.startPlayback(with: arrangement)
        }
    }

    func queueArrangement(_ arrangement: Arrangement) {
        schedulerQueue.async {
            guard self.isRunning else {
                self.startPlayback(with: arrangement)
                return
            }

            self.desiredRenderedArrangement = self.renderArrangement(arrangement)
            self.publishPendingStateIfNeeded()
        }
    }

    func updateMutedLaneIDs(_ mutedLaneIDs: Set<String>) {
        schedulerQueue.async {
            guard self.isRunning else { return }

            if var current = self.currentRenderedArrangement {
                current.arrangement = Arrangement(
                    variant: current.arrangement.variant,
                    cycle: current.arrangement.cycle,
                    bpm: current.arrangement.bpm,
                    samplePack: current.arrangement.samplePack,
                    mutedLaneIDs: mutedLaneIDs
                )
                self.currentRenderedArrangement = current
                self.updateLaneVolumes(using: current.arrangement)
            }
        }
    }

    func stop() {
        schedulerQueue.async {
            self.stopPlayback()
        }
    }

    private func startPlayback(with arrangement: Arrangement) {
        let renderedArrangement = renderArrangement(arrangement)
        let startHostTime = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: startLeadTime)

        stopNodes()

        currentRenderedArrangement = renderedArrangement
        desiredRenderedArrangement = nil
        scheduledRenderedArrangement = nil
        scheduledApplyHostTime = nil
        cycleStartHostTime = startHostTime
        isRunning = true
        lastPublishedStep = nil

        schedule(renderedArrangement, startingAt: startHostTime)
        updateLaneVolumes(using: arrangement)
        startClockTimerIfNeeded()
        publishPendingStateIfNeeded()
        publishStep(nil)
    }

    private func stopPlayback() {
        isRunning = false
        desiredRenderedArrangement = nil
        scheduledRenderedArrangement = nil
        scheduledApplyHostTime = nil
        currentRenderedArrangement = nil
        cycleStartHostTime = nil
        lastPublishedStep = nil

        if let clockTimer {
            clockTimer.cancel()
            self.clockTimer = nil
        }

        stopNodes()
        publishPendingStateIfNeeded()
        publishStep(nil)
    }

    private func handleClockTick() {
        let currentHostTime = mach_absolute_time()

        applyScheduledArrangementIfNeeded(at: currentHostTime)
        scheduleDesiredArrangementIfNeeded(at: currentHostTime)
        publishCurrentStepIfNeeded(at: currentHostTime)
        publishPendingStateIfNeeded()
    }

    private func applyScheduledArrangementIfNeeded(at currentHostTime: UInt64) {
        guard
            let applyHostTime = scheduledApplyHostTime,
            currentHostTime >= applyHostTime,
            let scheduledRenderedArrangement
        else {
            return
        }

        currentRenderedArrangement = scheduledRenderedArrangement
        self.scheduledRenderedArrangement = nil
        scheduledApplyHostTime = nil
        cycleStartHostTime = applyHostTime
        lastPublishedStep = nil
        updateLaneVolumes(using: scheduledRenderedArrangement.arrangement)
        publishArrangementApplied(scheduledRenderedArrangement.arrangement)
    }

    private func scheduleDesiredArrangementIfNeeded(at currentHostTime: UInt64) {
        guard
            isRunning,
            scheduledRenderedArrangement == nil,
            let currentRenderedArrangement,
            let desiredRenderedArrangement,
            let cycleStartHostTime
        else {
            return
        }

        let nextCycleStart = nextCycleStartHostTime(
            after: currentHostTime,
            cycleStartHostTime: cycleStartHostTime,
            cycleDurationHostTime: currentRenderedArrangement.cycleDurationHostTime
        )
        let remainingSeconds = AVAudioTime.seconds(forHostTime: nextCycleStart - currentHostTime)
        guard remainingSeconds <= queueLeadTime else { return }

        scheduleReplacement(desiredRenderedArrangement)
        scheduledApplyHostTime = nextCycleStart
        self.scheduledRenderedArrangement = desiredRenderedArrangement
        self.desiredRenderedArrangement = nil
    }

    private func publishCurrentStepIfNeeded(at currentHostTime: UInt64) {
        if desiredRenderedArrangement != nil || scheduledRenderedArrangement != nil {
            guard lastPublishedStep != nil else { return }
            lastPublishedStep = nil
            publishStep(nil)
            return
        }

        guard
            isRunning,
            let currentRenderedArrangement,
            let cycleStartHostTime,
            currentHostTime >= cycleStartHostTime
        else {
            guard lastPublishedStep != nil else { return }
            lastPublishedStep = nil
            publishStep(nil)
            return
        }

        let elapsedHostTime = currentHostTime - cycleStartHostTime
        let cyclePosition = elapsedHostTime % currentRenderedArrangement.cycleDurationHostTime
        let elapsedSeconds = AVAudioTime.seconds(forHostTime: cyclePosition)
        let rawStep = Int(elapsedSeconds / currentRenderedArrangement.stepDuration)
        let step = min(max(rawStep, 0), currentRenderedArrangement.arrangement.cycle.stepCount - 1)

        guard step != lastPublishedStep else { return }
        lastPublishedStep = step
        publishStep(step)
    }

    private func publishStep(_ step: Int?) {
        Task { @MainActor in
            self.onStep?(step)
        }
    }

    private func publishArrangementApplied(_ arrangement: Arrangement) {
        Task { @MainActor in
            self.onArrangementApplied?(arrangement)
        }
    }

    private func publishPendingStateIfNeeded() {
        let isPending = desiredRenderedArrangement != nil || scheduledRenderedArrangement != nil
        guard isPending != lastPublishedPendingState else { return }
        lastPublishedPendingState = isPending

        Task { @MainActor in
            self.onPendingStateChange?(isPending)
        }
    }

    private func startClockTimerIfNeeded() {
        guard clockTimer == nil else { return }

        let clockTimer = DispatchSource.makeTimerSource(queue: schedulerQueue)
        clockTimer.schedule(deadline: .now(), repeating: clockInterval)
        clockTimer.setEventHandler { [weak self] in
            self?.handleClockTick()
        }
        clockTimer.resume()
        self.clockTimer = clockTimer
    }

    private func schedule(_ arrangement: RenderedArrangement, startingAt hostTime: UInt64) {
        let startTime = AVAudioTime(hostTime: hostTime)

        for role in LaneRole.allCases {
            guard let node = laneNodes[role] else { continue }
            guard let buffer = arrangement.laneBuffers[role] else { continue }

            node.scheduleBuffer(buffer, at: startTime, options: [.loops], completionHandler: nil)
            node.play(at: startTime)
        }
    }

    private func scheduleReplacement(_ arrangement: RenderedArrangement) {
        for role in LaneRole.allCases {
            guard let node = laneNodes[role] else { continue }
            guard let buffer = arrangement.laneBuffers[role] else { continue }

            node.scheduleBuffer(
                buffer,
                at: nil,
                options: [.loops, .interruptsAtLoop],
                completionHandler: nil
            )
        }
    }

    private func stopNodes() {
        for node in laneNodes.values {
            node.stop()
        }
    }

    private func updateLaneVolumes(using arrangement: Arrangement) {
        let lanesByRole = Dictionary(uniqueKeysWithValues: arrangement.variant.lanes.map { ($0.role, $0) })

        for role in LaneRole.allCases {
            guard let node = laneNodes[role] else { continue }
            guard let lane = lanesByRole[role] else {
                node.volume = 0
                continue
            }

            node.volume = arrangement.mutedLaneIDs.contains(lane.id) ? 0 : 1
        }
    }

    private func renderArrangement(_ arrangement: Arrangement) -> RenderedArrangement {
        updateBuffersIfNeeded(for: arrangement.samplePack)

        let sanitizedBPM = sanitizedBPM(arrangement.bpm)
        let stepDuration = arrangement.cycle.durationPerStep(at: sanitizedBPM)
        let cycleDuration = stepDuration * Double(arrangement.cycle.stepCount)
        let cycleFrameCount = max(
            AVAudioFrameCount((cycleDuration * format.sampleRate).rounded()),
            1
        )

        let lanesByRole = Dictionary(uniqueKeysWithValues: arrangement.variant.lanes.map { ($0.role, $0) })
        var laneBuffers: [LaneRole: AVAudioPCMBuffer] = [:]

        for role in LaneRole.allCases {
            laneBuffers[role] = makeLoopBuffer(
                for: lanesByRole[role],
                stepDuration: stepDuration,
                cycleFrameCount: cycleFrameCount
            )
        }

        return RenderedArrangement(
            arrangement: arrangement,
            laneBuffers: laneBuffers,
            cycleFrameCount: cycleFrameCount,
            stepDuration: stepDuration,
            cycleDurationHostTime: max(AVAudioTime.hostTime(forSeconds: cycleDuration), 1)
        )
    }

    private func makeLoopBuffer(
        for lane: RhythmLane?,
        stepDuration: TimeInterval,
        cycleFrameCount: AVAudioFrameCount
    ) -> AVAudioPCMBuffer {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: cycleFrameCount
        ) else {
            fatalError("Failed to allocate loop buffer")
        }

        buffer.frameLength = cycleFrameCount

        guard let destination = buffer.floatChannelData?[0] else {
            return buffer
        }

        let frameCount = Int(cycleFrameCount)
        for index in 0..<frameCount {
            destination[index] = 0
        }

        guard let lane else { return buffer }
        guard let sourceBuffer = activeBuffers[lane.voice] else { return buffer }
        guard let source = sourceBuffer.floatChannelData?[0] else { return buffer }

        let framesPerStep = stepDuration * format.sampleRate
        let sourceFrameCount = Int(sourceBuffer.frameLength)

        for event in lane.events {
            let startFrame = Int((Double(event.step) * framesPerStep).rounded())
            mix(
                source: source,
                sourceFrameCount: sourceFrameCount,
                into: destination,
                destinationFrameCount: frameCount,
                startFrame: startFrame,
                gain: Float(event.intensity)
            )
        }

        for index in 0..<frameCount {
            destination[index] = destination[index].clamped(to: -1...1)
        }

        return buffer
    }

    private func mix(
        source: UnsafeMutablePointer<Float>,
        sourceFrameCount: Int,
        into destination: UnsafeMutablePointer<Float>,
        destinationFrameCount: Int,
        startFrame: Int,
        gain: Float
    ) {
        guard destinationFrameCount > 0 else { return }

        for frame in 0..<sourceFrameCount {
            let destinationIndex = (startFrame + frame) % destinationFrameCount
            destination[destinationIndex] += source[frame] * gain
        }
    }

    private func nextCycleStartHostTime(
        after currentHostTime: UInt64,
        cycleStartHostTime: UInt64,
        cycleDurationHostTime: UInt64
    ) -> UInt64 {
        guard currentHostTime > cycleStartHostTime else {
            return cycleStartHostTime
        }

        let elapsed = currentHostTime - cycleStartHostTime
        let cyclesCompleted = elapsed / cycleDurationHostTime
        let cycleStart = cycleStartHostTime + (cyclesCompleted * cycleDurationHostTime)

        if elapsed % cycleDurationHostTime == 0 {
            return cycleStart
        }

        return cycleStart + cycleDurationHostTime
    }

    private func sanitizedBPM(_ bpm: Double) -> Double {
        guard bpm.isFinite, bpm > 0 else {
            return 120
        }
        return bpm
    }

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(format.sampleRate)
            try session.setPreferredIOBufferDuration(0.005)
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
        }
        activeBuffers = defaultBuffers

        for role in LaneRole.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            laneNodes[role] = node
        }

        do {
            try engine.start()
        } catch {
            assertionFailure("Failed to start audio engine: \(error)")
        }
    }

    private func updateBuffersIfNeeded(for samplePack: RhythmSamplePack?) {
        let targetPackID = samplePack?.id
        guard activeSamplePackID != targetPackID else { return }

        var nextBuffers = defaultBuffers
        if let samplePack {
            for (voice, reference) in samplePack.voices {
                if let sampleBuffer = loadSampleBuffer(reference) {
                    nextBuffers[voice] = sampleBuffer
                }
            }
        }

        activeBuffers = nextBuffers
        activeSamplePackID = targetPackID
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

private struct SeededNoise {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1
        let value = Double((state >> 33) & 0xFFFF) / Double(0xFFFF)
        return (value * 2) - 1
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

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
