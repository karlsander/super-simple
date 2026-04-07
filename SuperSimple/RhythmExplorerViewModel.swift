import Foundation

@MainActor
final class RhythmExplorerViewModel: ObservableObject {
    @Published var selectedRegion: RhythmRegion = .all {
        didSet { syncSelectionToFilter() }
    }

    @Published private(set) var rhythms: [RhythmDefinition] = RhythmDatabase.all
    @Published private(set) var selectedRhythmID: String
    @Published private(set) var selectedVariantID: String
    @Published var bpm: Double
    @Published private(set) var listeningMode: ListeningMode = .fullMix
    @Published private(set) var isPlaying = false
    @Published private(set) var currentStep: Int?
    @Published private(set) var mutedLaneIDs: Set<String> = []
    @Published private(set) var mutedHitKeys: Set<MutedHitKey> = []

    let playback = RhythmPlaybackEngine()

    init() {
        let starter = RhythmDatabase.all.first { $0.id == "cumbia" } ?? RhythmDatabase.all[0]
        selectedRhythmID = starter.id
        selectedVariantID = starter.defaultVariant.id
        bpm = starter.defaultTempo

        playback.onStep = { [weak self] step in
            self?.currentStep = step
        }

        startPlayback()
    }

    var filteredRhythms: [RhythmDefinition] {
        guard selectedRegion != .all else { return rhythms }
        return rhythms.filter { $0.region == selectedRegion }
    }

    var selectedRhythm: RhythmDefinition {
        rhythms.first(where: { $0.id == selectedRhythmID }) ?? rhythms[0]
    }

    var selectedVariant: RhythmVariant {
        selectedRhythm.variants.first(where: { $0.id == selectedVariantID }) ?? selectedRhythm.defaultVariant
    }

    var sliderRange: ClosedRange<Double> {
        let nativeRange = selectedRhythm.tempoRange
        let lower = max(55, nativeRange.lowerBound - 24)
        let upper = min(190, nativeRange.upperBound + 24)
        return lower...upper
    }

    func selectRegion(_ region: RhythmRegion) {
        selectedRegion = region
    }

    func selectRhythm(_ rhythm: RhythmDefinition) {
        guard selectedRhythmID != rhythm.id else { return }

        selectedRhythmID = rhythm.id
        selectedVariantID = rhythm.defaultVariant.id
        bpm = rhythm.defaultTempo
        mutedLaneIDs = []
        mutedHitKeys = []
        currentStep = nil
        startPlayback()
    }

    func selectVariant(_ variant: RhythmVariant) {
        guard selectedVariantID != variant.id else { return }
        selectedVariantID = variant.id
        mutedLaneIDs = []
        mutedHitKeys = []
        currentStep = nil
        startPlayback()
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
        restartPlaybackIfNeeded()
    }

    func setListeningMode(_ mode: ListeningMode) {
        guard listeningMode != mode else { return }
        listeningMode = mode
        restartPlaybackIfNeeded()
    }

    func toggleLaneMute(_ laneID: String) {
        if mutedLaneIDs.contains(laneID) {
            mutedLaneIDs.remove(laneID)
        } else {
            mutedLaneIDs.insert(laneID)
        }
        restartPlaybackIfNeeded()
    }

    func toggleHitMute(laneID: String, step: Int) {
        guard selectedVariant.lanes.contains(where: { $0.id == laneID && $0.event(at: step) != nil }) else { return }

        let key = MutedHitKey(
            rhythmID: selectedRhythm.id,
            variantID: selectedVariant.id,
            laneID: laneID,
            step: step
        )

        if mutedHitKeys.contains(key) {
            mutedHitKeys.remove(key)
        } else {
            mutedHitKeys.insert(key)
        }
        restartPlaybackIfNeeded()
    }

    func isLaneMuted(_ laneID: String) -> Bool {
        mutedLaneIDs.contains(laneID)
    }

    func isHitMuted(laneID: String, step: Int) -> Bool {
        mutedHitKeys.contains(
            MutedHitKey(
                rhythmID: selectedRhythm.id,
                variantID: selectedVariant.id,
                laneID: laneID,
                step: step
            )
        )
    }

    func resetMutes() {
        mutedLaneIDs = []
        mutedHitKeys = []
        restartPlaybackIfNeeded()
    }

    func shouldEmphasizeLane(_ lane: RhythmLane) -> Bool {
        listeningMode.emphasizes(lane.role)
    }

    private func syncSelectionToFilter() {
        guard selectedRegion != .all else { return }
        if !filteredRhythms.contains(where: { $0.id == selectedRhythmID }), let replacement = filteredRhythms.first {
            selectRhythm(replacement)
        }
    }

    private func restartPlaybackIfNeeded() {
        guard isPlaying else { return }
        startPlayback()
    }

    private func startPlayback() {
        isPlaying = true
        playback.play(
            rhythmID: selectedRhythm.id,
            variant: selectedVariant,
            cycle: selectedRhythm.cycle,
            bpm: bpm,
            listeningMode: listeningMode,
            mutedLaneIDs: mutedLaneIDs,
            mutedHitKeys: mutedHitKeys
        )
    }

    private func stopPlayback() {
        isPlaying = false
        currentStep = nil
        playback.stop()
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
