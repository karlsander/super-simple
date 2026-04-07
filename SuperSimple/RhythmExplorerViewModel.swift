import Foundation

@MainActor
final class RhythmExplorerViewModel: ObservableObject {
    @Published private(set) var rhythms: [RhythmDefinition] = RhythmDatabase.all
    @Published private(set) var samplePacks: [RhythmSamplePack]
    @Published private(set) var selectedRhythmID: String
    @Published private(set) var selectedVariantID: String
    @Published private(set) var selectedSamplePackID: String
    @Published private(set) var bpm: Double
    @Published private(set) var isPlaying = false
    @Published private(set) var currentStep: Int?
    @Published private(set) var mutedLaneIDs: Set<String> = []
    @Published private(set) var hasPendingCycleChange = false

    let playback = RhythmPlaybackEngine()

    init() {
        let starter = RhythmDatabase.all.first { $0.id == "cumbia" } ?? RhythmDatabase.all[0]
        let availableSamplePacks = SampleLibrary.availablePacks()
        let defaultPack = availableSamplePacks.first { $0.id == "acousticdry" }
            ?? availableSamplePacks.first
            ?? .synthDefault

        samplePacks = availableSamplePacks
        selectedRhythmID = starter.id
        selectedVariantID = starter.defaultVariant.id
        selectedSamplePackID = defaultPack.id
        bpm = starter.defaultTempo
        mutedLaneIDs = Self.defaultMutedLaneIDs(for: starter.defaultVariant)

        playback.onStep = { [weak self] step in
            self?.currentStep = step
        }

        playback.onPendingStateChange = { [weak self] isPending in
            guard let self else { return }
            self.hasPendingCycleChange = isPending
            if isPending {
                self.currentStep = nil
            }
        }

        startPlayback()
    }

    var selectedRhythm: RhythmDefinition {
        rhythms.first(where: { $0.id == selectedRhythmID }) ?? rhythms[0]
    }

    var selectedVariant: RhythmVariant {
        selectedRhythm.variants.first(where: { $0.id == selectedVariantID }) ?? selectedRhythm.defaultVariant
    }

    var selectedSamplePack: RhythmSamplePack {
        samplePacks.first(where: { $0.id == selectedSamplePackID }) ?? samplePacks[0]
    }

    var sliderRange: ClosedRange<Double> {
        let nativeRange = selectedRhythm.tempoRange
        let lower = max(55, nativeRange.lowerBound - 24)
        let upper = min(190, nativeRange.upperBound + 24)
        return lower...upper
    }

    func selectRhythm(_ rhythm: RhythmDefinition) {
        guard selectedRhythmID != rhythm.id else { return }

        selectedRhythmID = rhythm.id
        selectedVariantID = rhythm.defaultVariant.id
        bpm = rhythm.defaultTempo
        mutedLaneIDs = Self.defaultMutedLaneIDs(for: rhythm.defaultVariant)
        currentStep = nil
        queueArrangementIfNeeded()
    }

    func selectVariant(_ variant: RhythmVariant) {
        guard selectedVariantID != variant.id else { return }
        selectedVariantID = variant.id
        mutedLaneIDs = Self.defaultMutedLaneIDs(for: variant)
        currentStep = nil
        queueArrangementIfNeeded()
    }

    func selectSamplePack(_ samplePack: RhythmSamplePack) {
        guard selectedSamplePackID != samplePack.id else { return }
        selectedSamplePackID = samplePack.id
        currentStep = nil
        queueArrangementIfNeeded()
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func setTempo(_ newTempo: Double) {
        bpm = newTempo.clamped(to: sliderRange)
        queueArrangementIfNeeded()
    }

    func toggleLaneMute(_ laneID: String) {
        if mutedLaneIDs.contains(laneID) {
            mutedLaneIDs.remove(laneID)
        } else {
            mutedLaneIDs.insert(laneID)
        }
        if isPlaying, !hasPendingCycleChange {
            playback.updateMutedLaneIDs(mutedLaneIDs)
        }
    }

    func isLaneMuted(_ laneID: String) -> Bool {
        mutedLaneIDs.contains(laneID)
    }

    private var selectedArrangement: RhythmPlaybackEngine.Arrangement {
        RhythmPlaybackEngine.Arrangement(
            variant: selectedVariant,
            cycle: selectedRhythm.cycle,
            bpm: bpm,
            samplePack: selectedSamplePack.isBuiltInSynth ? nil : selectedSamplePack,
            mutedLaneIDs: mutedLaneIDs
        )
    }

    private func queueArrangementIfNeeded() {
        guard isPlaying else { return }
        playback.queueArrangement(selectedArrangement)
    }

    private func startPlayback() {
        isPlaying = true
        hasPendingCycleChange = false
        playback.start(arrangement: selectedArrangement)
    }

    private func stopPlayback() {
        isPlaying = false
        hasPendingCycleChange = false
        currentStep = nil
        playback.stop()
    }

    private static func defaultMutedLaneIDs(for variant: RhythmVariant) -> Set<String> {
        Set(
            variant.lanes
                .filter { $0.voice == .click }
                .map(\.id)
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
