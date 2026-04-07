import Foundation

@MainActor
final class RhythmExplorerViewModel: ObservableObject {
    @Published var selectedRegion: RhythmRegion = .all {
        didSet { syncSelectionToFilter() }
    }

    @Published private(set) var rhythms: [RhythmDefinition] = RhythmDatabase.all
    @Published private(set) var samplePacks: [RhythmSamplePack]
    @Published private(set) var selectedRhythmID: String
    @Published private(set) var selectedVariantID: String
    @Published private(set) var selectedSamplePackID: String
    @Published private(set) var bpm: Double
    @Published private(set) var isPlaying = false
    @Published private(set) var currentStep: Int?
    @Published private(set) var mutedLaneIDs: Set<String> = []

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

    var selectedSamplePack: RhythmSamplePack {
        samplePacks.first(where: { $0.id == selectedSamplePackID }) ?? samplePacks[0]
    }

    var sliderRange: ClosedRange<Double> {
        let nativeRange = selectedRhythm.tempoRange
        let lower = max(55, nativeRange.lowerBound - 24)
        let upper = min(190, nativeRange.upperBound + 24)
        return lower...upper
    }

    var nearbyRhythms: [RhythmDefinition] {
        selectedRhythm.relatedRhythmIDs.compactMap { relatedID in
            rhythms.first { $0.id == relatedID }
        }
    }

    func selectRegion(_ region: RhythmRegion) {
        selectedRegion = region
    }

    func selectRhythm(_ rhythm: RhythmDefinition) {
        guard selectedRhythmID != rhythm.id else { return }

        selectedRhythmID = rhythm.id
        selectedVariantID = rhythm.defaultVariant.id
        bpm = rhythm.defaultTempo
        mutedLaneIDs = Self.defaultMutedLaneIDs(for: rhythm.defaultVariant)
        currentStep = nil
        restartPlaybackIfNeeded()
    }

    func selectVariant(_ variant: RhythmVariant) {
        guard selectedVariantID != variant.id else { return }
        selectedVariantID = variant.id
        mutedLaneIDs = Self.defaultMutedLaneIDs(for: variant)
        currentStep = nil
        restartPlaybackIfNeeded()
    }

    func selectSamplePack(_ samplePack: RhythmSamplePack) {
        guard selectedSamplePackID != samplePack.id else { return }
        selectedSamplePackID = samplePack.id
        currentStep = nil
        restartPlaybackIfNeeded()
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

    func toggleLaneMute(_ laneID: String) {
        if mutedLaneIDs.contains(laneID) {
            mutedLaneIDs.remove(laneID)
        } else {
            mutedLaneIDs.insert(laneID)
        }
        restartPlaybackIfNeeded()
    }

    func isLaneMuted(_ laneID: String) -> Bool {
        mutedLaneIDs.contains(laneID)
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
            variant: selectedVariant,
            cycle: selectedRhythm.cycle,
            bpm: bpm,
            samplePack: selectedSamplePack.isBuiltInSynth ? nil : selectedSamplePack,
            mutedLaneIDs: mutedLaneIDs
        )
    }

    private func stopPlayback() {
        isPlaying = false
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
