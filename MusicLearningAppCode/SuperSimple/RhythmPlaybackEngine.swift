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
        let laneBuffers: [LaneSlot: AVAudioPCMBuffer]
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

    private var laneNodes: [LaneSlot: AVAudioPlayerNode] = [:]
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

    func updateSamplePack(_ samplePack: RhythmSamplePack?) {
        schedulerQueue.async {
            if let currentRenderedArrangement = self.currentRenderedArrangement {
                self.currentRenderedArrangement = self.renderArrangement(
                    self.arrangement(currentRenderedArrangement.arrangement, replacingSamplePackWith: samplePack)
                )
            }

            if let desiredRenderedArrangement = self.desiredRenderedArrangement {
                self.desiredRenderedArrangement = self.renderArrangement(
                    self.arrangement(desiredRenderedArrangement.arrangement, replacingSamplePackWith: samplePack)
                )
            }

            if let scheduledRenderedArrangement = self.scheduledRenderedArrangement {
                self.scheduledRenderedArrangement = self.renderArrangement(
                    self.arrangement(scheduledRenderedArrangement.arrangement, replacingSamplePackWith: samplePack)
                )
            }

            guard self.isRunning else { return }
            self.reschedulePlaybackAfterImmediateSamplePackChange()
        }
    }

    func updateTempo(_ bpm: Double) {
        schedulerQueue.async {
            let currentHostTime = mach_absolute_time()
            self.applyScheduledArrangementIfNeeded(at: currentHostTime)

            guard let previousCurrentRenderedArrangement = self.currentRenderedArrangement else { return }

            self.currentRenderedArrangement = self.renderArrangement(
                self.arrangement(previousCurrentRenderedArrangement.arrangement, replacingBPMWith: bpm)
            )

            if let desiredRenderedArrangement = self.desiredRenderedArrangement {
                self.desiredRenderedArrangement = self.renderArrangement(
                    self.arrangement(desiredRenderedArrangement.arrangement, replacingBPMWith: bpm)
                )
            }

            if let scheduledRenderedArrangement = self.scheduledRenderedArrangement {
                self.scheduledRenderedArrangement = self.renderArrangement(
                    self.arrangement(scheduledRenderedArrangement.arrangement, replacingBPMWith: bpm)
                )
            }

            guard self.isRunning else { return }
            self.reschedulePlaybackAfterImmediateTempoChange(
                previousCurrentRenderedArrangement: previousCurrentRenderedArrangement,
                currentHostTime: currentHostTime
            )
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

        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let buffer = arrangement.laneBuffers[slot] else { continue }

            node.scheduleBuffer(buffer, at: startTime, options: [.loops], completionHandler: nil)
            node.play(at: startTime)
        }
    }

    private func scheduleLoop(_ arrangement: RenderedArrangement, startingAt hostTime: UInt64) {
        let startTime = AVAudioTime(hostTime: hostTime)

        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let buffer = arrangement.laneBuffers[slot] else { continue }

            node.scheduleBuffer(buffer, at: startTime, options: [.loops], completionHandler: nil)
        }
    }

    private func scheduleImmediateLoop(_ arrangement: RenderedArrangement) {
        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let buffer = arrangement.laneBuffers[slot] else { continue }

            node.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            node.play()
        }
    }

    private func scheduleReplacement(_ arrangement: RenderedArrangement) {
        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let buffer = arrangement.laneBuffers[slot] else { continue }

            node.scheduleBuffer(
                buffer,
                at: nil,
                options: [.loops, .interruptsAtLoop],
                completionHandler: nil
            )
        }
    }

    private func scheduleTail(
        of arrangement: RenderedArrangement,
        startingAtFrame startFrame: Int
    ) {
        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let buffer = arrangement.laneBuffers[slot] else { continue }
            guard let tailBuffer = makeTailBuffer(from: buffer, startingAtFrame: startFrame) else { continue }

            node.scheduleBuffer(tailBuffer, at: nil, options: [.interrupts], completionHandler: nil)
            node.play()
        }
    }

    private func stopNodes() {
        for node in laneNodes.values {
            node.stop()
        }
    }

    private func updateLaneVolumes(using arrangement: Arrangement) {
        let lanesBySlot = Dictionary(uniqueKeysWithValues: arrangement.variant.lanes.map { ($0.slot, $0) })

        for slot in LaneSlot.allCases {
            guard let node = laneNodes[slot] else { continue }
            guard let lane = lanesBySlot[slot] else {
                node.volume = 0
                continue
            }

            node.volume = arrangement.mutedLaneIDs.contains(lane.id) ? 0 : 1
        }
    }

    private func arrangement(
        _ arrangement: Arrangement,
        replacingSamplePackWith samplePack: RhythmSamplePack?
    ) -> Arrangement {
        Arrangement(
            variant: arrangement.variant,
            cycle: arrangement.cycle,
            bpm: arrangement.bpm,
            samplePack: samplePack,
            mutedLaneIDs: arrangement.mutedLaneIDs
        )
    }

    private func arrangement(
        _ arrangement: Arrangement,
        replacingBPMWith bpm: Double
    ) -> Arrangement {
        Arrangement(
            variant: arrangement.variant,
            cycle: arrangement.cycle,
            bpm: bpm,
            samplePack: arrangement.samplePack,
            mutedLaneIDs: arrangement.mutedLaneIDs
        )
    }

    private func reschedulePlaybackAfterImmediateSamplePackChange() {
        let currentHostTime = mach_absolute_time()
        applyScheduledArrangementIfNeeded(at: currentHostTime)

        guard
            isRunning,
            let currentRenderedArrangement
        else {
            return
        }

        stopNodes()

        guard let cycleStartHostTime else {
            self.cycleStartHostTime = currentHostTime
            scheduleImmediateLoop(currentRenderedArrangement)
            updateLaneVolumes(using: currentRenderedArrangement.arrangement)
            publishPendingStateIfNeeded()
            return
        }

        if currentHostTime < cycleStartHostTime {
            schedule(currentRenderedArrangement, startingAt: cycleStartHostTime)

            if
                let scheduledRenderedArrangement,
                let scheduledApplyHostTime
            {
                scheduleLoop(scheduledRenderedArrangement, startingAt: scheduledApplyHostTime)
            }

            updateLaneVolumes(using: currentRenderedArrangement.arrangement)
            publishPendingStateIfNeeded()
            return
        }

        let upcomingScheduledArrangement: (arrangement: RenderedArrangement, applyHostTime: UInt64)?
        if
            let scheduledRenderedArrangement,
            let scheduledApplyHostTime
        {
            upcomingScheduledArrangement = (scheduledRenderedArrangement, scheduledApplyHostTime)
        } else if let desiredRenderedArrangement {
            let nextCycleStart = nextCycleStartHostTime(
                after: currentHostTime,
                cycleStartHostTime: cycleStartHostTime,
                cycleDurationHostTime: currentRenderedArrangement.cycleDurationHostTime
            )
            self.scheduledRenderedArrangement = desiredRenderedArrangement
            self.scheduledApplyHostTime = nextCycleStart
            self.desiredRenderedArrangement = nil
            upcomingScheduledArrangement = (desiredRenderedArrangement, nextCycleStart)
        } else {
            upcomingScheduledArrangement = nil
        }

        let cyclePositionHostTime = (currentHostTime - cycleStartHostTime) % currentRenderedArrangement.cycleDurationHostTime
        let frameOffset = frameOffset(
            for: cyclePositionHostTime,
            in: currentRenderedArrangement
        )

        if frameOffset == 0 {
            self.cycleStartHostTime = currentHostTime
            scheduleImmediateLoop(currentRenderedArrangement)

            if let upcomingScheduledArrangement {
                scheduleLoop(
                    upcomingScheduledArrangement.arrangement,
                    startingAt: upcomingScheduledArrangement.applyHostTime
                )
            }
        } else {
            scheduleTail(of: currentRenderedArrangement, startingAtFrame: frameOffset)

            if let upcomingScheduledArrangement {
                scheduleLoop(
                    upcomingScheduledArrangement.arrangement,
                    startingAt: upcomingScheduledArrangement.applyHostTime
                )
            } else {
                let nextCycleStart = nextCycleStartHostTime(
                    after: currentHostTime,
                    cycleStartHostTime: cycleStartHostTime,
                    cycleDurationHostTime: currentRenderedArrangement.cycleDurationHostTime
                )
                scheduleLoop(currentRenderedArrangement, startingAt: nextCycleStart)
            }
        }

        updateLaneVolumes(using: currentRenderedArrangement.arrangement)
        publishPendingStateIfNeeded()
    }

    private func reschedulePlaybackAfterImmediateTempoChange(
        previousCurrentRenderedArrangement: RenderedArrangement,
        currentHostTime: UInt64
    ) {
        guard
            isRunning,
            let currentRenderedArrangement
        else {
            return
        }

        stopNodes()

        guard let cycleStartHostTime else {
            self.cycleStartHostTime = currentHostTime
            scheduleImmediateLoop(currentRenderedArrangement)
            let nextCycleStart = currentHostTime + currentRenderedArrangement.cycleDurationHostTime
            if let upcomingArrangement = upcomingArrangementForImmediateReschedule(applyAt: nextCycleStart) {
                scheduleLoop(upcomingArrangement, startingAt: nextCycleStart)
            }
            updateLaneVolumes(using: currentRenderedArrangement.arrangement)
            publishPendingStateIfNeeded()
            return
        }

        if currentHostTime < cycleStartHostTime {
            schedule(currentRenderedArrangement, startingAt: cycleStartHostTime)

            let nextCycleStart = cycleStartHostTime + currentRenderedArrangement.cycleDurationHostTime
            if let upcomingArrangement = upcomingArrangementForImmediateReschedule(applyAt: nextCycleStart) {
                scheduleLoop(upcomingArrangement, startingAt: nextCycleStart)
            }

            updateLaneVolumes(using: currentRenderedArrangement.arrangement)
            publishPendingStateIfNeeded()
            return
        }

        let cycleProgress = cycleProgress(
            at: currentHostTime,
            in: previousCurrentRenderedArrangement,
            cycleStartHostTime: cycleStartHostTime
        )
        let cycleStartOffset = hostOffset(for: cycleProgress, in: currentRenderedArrangement)
        let adjustedCycleStartHostTime = currentHostTime - cycleStartOffset
        let nextCycleStart = adjustedCycleStartHostTime + currentRenderedArrangement.cycleDurationHostTime
        let upcomingArrangement = upcomingArrangementForImmediateReschedule(applyAt: nextCycleStart)

        if cycleProgress == 0 {
            self.cycleStartHostTime = currentHostTime
            scheduleImmediateLoop(currentRenderedArrangement)
        } else {
            self.cycleStartHostTime = adjustedCycleStartHostTime

            let frameOffset = frameOffset(
                forCycleProgress: cycleProgress,
                in: currentRenderedArrangement
            )
            scheduleTail(of: currentRenderedArrangement, startingAtFrame: frameOffset)

            if upcomingArrangement == nil {
                scheduleLoop(currentRenderedArrangement, startingAt: nextCycleStart)
            }
        }

        if let upcomingArrangement {
            scheduleLoop(upcomingArrangement, startingAt: nextCycleStart)
        }

        updateLaneVolumes(using: currentRenderedArrangement.arrangement)
        publishPendingStateIfNeeded()
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

        let lanesBySlot = Dictionary(uniqueKeysWithValues: arrangement.variant.lanes.map { ($0.slot, $0) })
        var laneBuffers: [LaneSlot: AVAudioPCMBuffer] = [:]

        for slot in LaneSlot.allCases {
            laneBuffers[slot] = makeLoopBuffer(
                for: lanesBySlot[slot],
                cycle: arrangement.cycle,
                swingAmount: arrangement.variant.swingAmount,
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

    private func frameOffset(
        for cyclePositionHostTime: UInt64,
        in arrangement: RenderedArrangement
    ) -> Int {
        let cycleFrameCount = Int(arrangement.cycleFrameCount)
        guard cycleFrameCount > 0 else { return 0 }

        let cyclePositionSeconds = AVAudioTime.seconds(forHostTime: cyclePositionHostTime)
        let rawFrameOffset = Int((cyclePositionSeconds * format.sampleRate).rounded(.down))
        return min(max(rawFrameOffset, 0), max(cycleFrameCount - 1, 0))
    }

    private func frameOffset(
        forCycleProgress cycleProgress: Double,
        in arrangement: RenderedArrangement
    ) -> Int {
        let cycleFrameCount = Int(arrangement.cycleFrameCount)
        guard cycleFrameCount > 0 else { return 0 }

        let rawFrameOffset = Int((Double(cycleFrameCount) * cycleProgress).rounded(.down))
        return min(max(rawFrameOffset, 0), max(cycleFrameCount - 1, 0))
    }

    private func cycleProgress(
        at currentHostTime: UInt64,
        in arrangement: RenderedArrangement,
        cycleStartHostTime: UInt64
    ) -> Double {
        guard currentHostTime >= cycleStartHostTime else { return 0 }

        let cyclePositionHostTime = (currentHostTime - cycleStartHostTime) % arrangement.cycleDurationHostTime
        return Double(cyclePositionHostTime) / Double(arrangement.cycleDurationHostTime)
    }

    private func hostOffset(
        for cycleProgress: Double,
        in arrangement: RenderedArrangement
    ) -> UInt64 {
        UInt64((Double(arrangement.cycleDurationHostTime) * cycleProgress).rounded(.down))
    }

    private func upcomingArrangementForImmediateReschedule(applyAt hostTime: UInt64) -> RenderedArrangement? {
        if let scheduledRenderedArrangement {
            scheduledApplyHostTime = hostTime
            return scheduledRenderedArrangement
        }

        if let desiredRenderedArrangement {
            self.scheduledRenderedArrangement = desiredRenderedArrangement
            self.scheduledApplyHostTime = hostTime
            self.desiredRenderedArrangement = nil
            return desiredRenderedArrangement
        }

        scheduledRenderedArrangement = nil
        scheduledApplyHostTime = nil
        return nil
    }

    private func makeTailBuffer(
        from buffer: AVAudioPCMBuffer,
        startingAtFrame startFrame: Int
    ) -> AVAudioPCMBuffer? {
        let sourceFrameCount = Int(buffer.frameLength)
        guard startFrame > 0, startFrame < sourceFrameCount else { return nil }
        guard let source = buffer.floatChannelData?[0] else { return nil }
        guard let tailBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(sourceFrameCount - startFrame)
        ) else {
            return nil
        }
        guard let destination = tailBuffer.floatChannelData?[0] else { return nil }

        let remainingFrameCount = sourceFrameCount - startFrame
        tailBuffer.frameLength = AVAudioFrameCount(remainingFrameCount)

        for frame in 0..<remainingFrameCount {
            destination[frame] = source[startFrame + frame]
        }

        return tailBuffer
    }

    private func makeLoopBuffer(
        for lane: RhythmLane?,
        cycle: RhythmCycle,
        swingAmount: Double,
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
            let stepOffset = lane.stepOffset(at: event.step, in: cycle, swingAmount: swingAmount)
            let startFrame = Int(((Double(event.step) + stepOffset) * framesPerStep).rounded())
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

        let mixFrameCount = min(sourceFrameCount, destinationFrameCount)
        for frame in 0..<mixFrameCount {
            let destinationIndex = wrappedFrameIndex(startFrame + frame, frameCount: destinationFrameCount)
            destination[destinationIndex] += source[frame] * gain
        }
    }

    private func wrappedFrameIndex(_ frame: Int, frameCount: Int) -> Int {
        guard frameCount > 0 else { return 0 }
        let wrapped = frame % frameCount
        return wrapped >= 0 ? wrapped : wrapped + frameCount
    }

    private func makeOneShotBuffer(
        from sourceBuffer: AVAudioPCMBuffer,
        for voice: InstrumentVoice
    ) -> AVAudioPCMBuffer? {
        let frameCount = Int(sourceBuffer.frameLength)
        guard frameCount > 0 else { return sourceBuffer }
        guard let source = sourceBuffer.floatChannelData?[0] else { return sourceBuffer }

        let peak = peakAmplitude(in: source, frameCount: frameCount)
        guard peak > 0.0001 else { return sourceBuffer }

        let profile = voice.sampleTrimProfile
        let onsetFrame = detectOnsetFrame(
            in: source,
            frameCount: frameCount,
            peak: peak,
            profile: profile
        )
        let preRollFrames = Int((profile.preRollDuration * format.sampleRate).rounded())
        let startFrame = max(0, onsetFrame - preRollFrames)

        let maxFrameCount = Int((profile.maxDuration * format.sampleRate).rounded())
        let searchEndFrame = min(frameCount, startFrame + max(maxFrameCount, 1))
        let endFrame = detectEndFrame(
            in: source,
            startFrame: startFrame,
            endFrameLimit: searchEndFrame,
            peak: peak,
            profile: profile
        )
        let trimmedFrameCount = max(1, endFrame - startFrame)

        guard let trimmedBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(trimmedFrameCount)
        ) else {
            return nil
        }
        guard let destination = trimmedBuffer.floatChannelData?[0] else { return nil }

        trimmedBuffer.frameLength = AVAudioFrameCount(trimmedFrameCount)
        for frame in 0..<trimmedFrameCount {
            destination[frame] = source[startFrame + frame]
        }

        applyEdgeFades(
            to: destination,
            frameCount: trimmedFrameCount,
            fadeInFrameCount: Int((profile.fadeInDuration * format.sampleRate).rounded()),
            fadeOutFrameCount: Int((profile.fadeOutDuration * format.sampleRate).rounded())
        )

        return trimmedBuffer
    }

    private func peakAmplitude(
        in source: UnsafeMutablePointer<Float>,
        frameCount: Int
    ) -> Float {
        var peak: Float = 0
        for frame in 0..<frameCount {
            peak = max(peak, abs(source[frame]))
        }
        return peak
    }

    private func detectOnsetFrame(
        in source: UnsafeMutablePointer<Float>,
        frameCount: Int,
        peak: Float,
        profile: SampleTrimProfile
    ) -> Int {
        let windowFrameCount = max(32, Int((profile.onsetWindowDuration * format.sampleRate).rounded()))
        let threshold = max(profile.minimumOnsetAmplitude, peak * profile.onsetThresholdRatio)
        var rollingMagnitude: Float = 0

        for frame in 0..<frameCount {
            rollingMagnitude += abs(source[frame])
            if frame >= windowFrameCount {
                rollingMagnitude -= abs(source[frame - windowFrameCount])
            }

            let averagedMagnitude = rollingMagnitude / Float(min(frame + 1, windowFrameCount))
            if averagedMagnitude >= threshold {
                return max(0, frame - (windowFrameCount / 2))
            }
        }

        return 0
    }

    private func detectEndFrame(
        in source: UnsafeMutablePointer<Float>,
        startFrame: Int,
        endFrameLimit: Int,
        peak: Float,
        profile: SampleTrimProfile
    ) -> Int {
        let tailThreshold = max(profile.minimumTailAmplitude, peak * profile.tailThresholdRatio)
        var lastSignificantFrame = startFrame

        for frame in startFrame..<endFrameLimit {
            if abs(source[frame]) >= tailThreshold {
                lastSignificantFrame = frame
            }
        }

        let releaseFrames = Int((profile.releaseTailDuration * format.sampleRate).rounded())
        let minimumFrames = Int((profile.minimumDuration * format.sampleRate).rounded())
        let minimumEndFrame = min(endFrameLimit, startFrame + max(minimumFrames, 1))
        let releaseEndFrame = min(endFrameLimit, lastSignificantFrame + releaseFrames)

        return max(minimumEndFrame, releaseEndFrame)
    }

    private func applyEdgeFades(
        to destination: UnsafeMutablePointer<Float>,
        frameCount: Int,
        fadeInFrameCount: Int,
        fadeOutFrameCount: Int
    ) {
        let safeFadeInFrameCount = min(frameCount, max(fadeInFrameCount, 0))
        if safeFadeInFrameCount > 1 {
            for frame in 0..<safeFadeInFrameCount {
                let gain = Float(frame) / Float(safeFadeInFrameCount - 1)
                destination[frame] *= gain
            }
        }

        let safeFadeOutFrameCount = min(frameCount, max(fadeOutFrameCount, 0))
        if safeFadeOutFrameCount > 1 {
            let startFrame = frameCount - safeFadeOutFrameCount
            for offset in 0..<safeFadeOutFrameCount {
                let gain = 1 - (Float(offset) / Float(safeFadeOutFrameCount - 1))
                destination[startFrame + offset] *= gain
            }
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

        for slot in LaneSlot.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            laneNodes[slot] = node
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
                guard voice != .click else { continue }
                if let sampleBuffer = loadSampleBuffer(reference, for: voice) {
                    nextBuffers[voice] = sampleBuffer
                }
            }
        }

        activeBuffers = nextBuffers
        activeSamplePackID = targetPackID
    }

    private func loadSampleBuffer(
        _ reference: RhythmSampleReference,
        for voice: InstrumentVoice
    ) -> AVAudioPCMBuffer? {
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

            let playbackBuffer: AVAudioPCMBuffer?
            if matchesPlaybackFormat(sourceFormat) {
                playbackBuffer = sourceBuffer
            } else {
                playbackBuffer = convertBuffer(sourceBuffer, from: sourceFormat)
            }

            guard let playbackBuffer else { return nil }
            return makeOneShotBuffer(from: playbackBuffer, for: voice)
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
        case .clap:
            samples = makeClap(duration: 0.12, amplitude: 0.58)
        case .crossStick:
            samples = makeWoodTone(duration: 0.06, frequency: 1_260, amplitude: 0.52)
        case .closedHat:
            samples = makeNoiseBurst(duration: 0.05, cutoff: 0.82, amplitude: 0.4, withTone: nil)
        case .openHat:
            samples = makeNoiseBurst(duration: 0.16, cutoff: 0.9, amplitude: 0.35, withTone: nil)
        case .hiHatFoot:
            samples = makeNoiseBurst(duration: 0.04, cutoff: 0.74, amplitude: 0.30, withTone: 460)
        case .ride:
            samples = makeBell(duration: 0.28, frequency: 980, amplitude: 0.34)
        case .brushTap:
            samples = makeNoiseBurst(duration: 0.10, cutoff: 0.28, amplitude: 0.26, withTone: 170)
        case .brushSweep:
            samples = makeBrushSweep(duration: 0.18, amplitude: 0.22)
        case .shaker:
            samples = makeNoiseBurst(duration: 0.07, cutoff: 0.66, amplitude: 0.28, withTone: nil)
        case .maraca:
            samples = makeNoiseBurst(duration: 0.06, cutoff: 0.78, amplitude: 0.24, withTone: nil)
        case .guache:
            samples = makeNoiseBurst(duration: 0.08, cutoff: 0.58, amplitude: 0.26, withTone: nil)
        case .clave:
            samples = makeWoodTone(duration: 0.07, frequency: 1_420, amplitude: 0.6)
        case .agogo:
            samples = makeBell(duration: 0.18, frequency: 1_220, amplitude: 0.38)
        case .tambora:
            samples = makeTom(duration: 0.18, frequency: 98, amplitude: 0.78)
        case .llamador:
            samples = makeTom(duration: 0.11, frequency: 205, amplitude: 0.42)
        case .alegre:
            samples = makeTom(duration: 0.12, frequency: 280, amplitude: 0.40)
        case .surdo:
            samples = makeTom(duration: 0.22, frequency: 82, amplitude: 0.88)
        case .pandeiro:
            samples = makeNoiseBurst(duration: 0.08, cutoff: 0.70, amplitude: 0.28, withTone: 920)
        case .tamborim:
            samples = makeWoodTone(duration: 0.05, frequency: 1_760, amplitude: 0.42)
        case .caixa:
            samples = makeNoiseBurst(duration: 0.10, cutoff: 0.34, amplitude: 0.48, withTone: 240)
        case .congaLow:
            samples = makeTom(duration: 0.17, frequency: 142, amplitude: 0.62)
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

    private func makeClap(duration: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        let transientOffsets = [0.0, 0.012, 0.024]
        var noises = transientOffsets.enumerated().map { index, _ in
            SeededNoise(seed: UInt64(91 + (index * 47)))
        }

        for index in 0..<count {
            let time = Double(index) / format.sampleRate
            var sample = 0.0

            for (transientIndex, offset) in transientOffsets.enumerated() {
                let localTime = time - offset
                guard localTime >= 0 else { continue }

                let localProgress = localTime / duration
                guard localProgress <= 1 else { continue }

                let envelope = exp(-18 * localProgress)
                let noise = noises[transientIndex].next()
                sample += noise * envelope
            }

            output[index] = Float(sample * amplitude)
        }

        return output
    }

    private func makeBrushSweep(duration: Double, amplitude: Double) -> [Float] {
        let count = Int(format.sampleRate * duration)
        var output = Array(repeating: Float.zero, count: count)
        var noise = SeededNoise(seed: 501)
        var lowPass = 0.0

        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let envelope = exp(-3.2 * progress)
            let raw = noise.next()
            lowPass += 0.14 * (raw - lowPass)
            let grain = 0.45 * sin(progress * .pi * 20)
            output[index] = Float((lowPass + grain * raw) * envelope * amplitude)
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

private struct SampleTrimProfile {
    let maxDuration: Double
    let minimumDuration: Double
    let preRollDuration: Double
    let releaseTailDuration: Double
    let fadeInDuration: Double
    let fadeOutDuration: Double
    let onsetWindowDuration: Double
    let onsetThresholdRatio: Float
    let tailThresholdRatio: Float
    let minimumOnsetAmplitude: Float
    let minimumTailAmplitude: Float
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
        .clap,
        .crossStick,
        .closedHat,
        .openHat,
        .hiHatFoot,
        .ride,
        .brushTap,
        .brushSweep,
        .shaker,
        .maraca,
        .guache,
        .clave,
        .agogo,
        .tambora,
        .llamador,
        .alegre,
        .surdo,
        .pandeiro,
        .tamborim,
        .caixa,
        .congaLow
    ]

    var sampleTrimProfile: SampleTrimProfile {
        switch self {
        case .click:
            SampleTrimProfile(
                maxDuration: 0.06,
                minimumDuration: 0.015,
                preRollDuration: 0.002,
                releaseTailDuration: 0.015,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.006,
                onsetWindowDuration: 0.0015,
                onsetThresholdRatio: 0.18,
                tailThresholdRatio: 0.05,
                minimumOnsetAmplitude: 0.01,
                minimumTailAmplitude: 0.003
            )
        case .kick, .surdo:
            SampleTrimProfile(
                maxDuration: 0.5,
                minimumDuration: 0.12,
                preRollDuration: 0.003,
                releaseTailDuration: 0.08,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.02,
                onsetWindowDuration: 0.002,
                onsetThresholdRatio: 0.12,
                tailThresholdRatio: 0.04,
                minimumOnsetAmplitude: 0.008,
                minimumTailAmplitude: 0.002
            )
        case .snare, .clap, .caixa, .brushTap:
            SampleTrimProfile(
                maxDuration: 0.24,
                minimumDuration: 0.05,
                preRollDuration: 0.003,
                releaseTailDuration: 0.04,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.015,
                onsetWindowDuration: 0.0015,
                onsetThresholdRatio: 0.14,
                tailThresholdRatio: 0.04,
                minimumOnsetAmplitude: 0.008,
                minimumTailAmplitude: 0.002
            )
        case .closedHat, .hiHatFoot, .shaker, .maraca, .guache, .tamborim:
            SampleTrimProfile(
                maxDuration: 0.14,
                minimumDuration: 0.03,
                preRollDuration: 0.002,
                releaseTailDuration: 0.025,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.01,
                onsetWindowDuration: 0.0015,
                onsetThresholdRatio: 0.15,
                tailThresholdRatio: 0.05,
                minimumOnsetAmplitude: 0.009,
                minimumTailAmplitude: 0.0025
            )
        case .openHat, .ride, .agogo, .brushSweep:
            SampleTrimProfile(
                maxDuration: 0.42,
                minimumDuration: 0.08,
                preRollDuration: 0.003,
                releaseTailDuration: 0.06,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.02,
                onsetWindowDuration: 0.002,
                onsetThresholdRatio: 0.12,
                tailThresholdRatio: 0.035,
                minimumOnsetAmplitude: 0.007,
                minimumTailAmplitude: 0.0015
            )
        case .crossStick, .clave:
            SampleTrimProfile(
                maxDuration: 0.12,
                minimumDuration: 0.03,
                preRollDuration: 0.002,
                releaseTailDuration: 0.025,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.008,
                onsetWindowDuration: 0.0015,
                onsetThresholdRatio: 0.15,
                tailThresholdRatio: 0.05,
                minimumOnsetAmplitude: 0.01,
                minimumTailAmplitude: 0.0025
            )
        case .tambora, .llamador, .alegre, .congaLow, .pandeiro:
            SampleTrimProfile(
                maxDuration: 0.26,
                minimumDuration: 0.06,
                preRollDuration: 0.003,
                releaseTailDuration: 0.045,
                fadeInDuration: 0.001,
                fadeOutDuration: 0.015,
                onsetWindowDuration: 0.002,
                onsetThresholdRatio: 0.13,
                tailThresholdRatio: 0.04,
                minimumOnsetAmplitude: 0.008,
                minimumTailAmplitude: 0.002
            )
        }
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
