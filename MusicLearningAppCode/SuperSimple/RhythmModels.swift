import Foundation

enum RhythmTier: String, CaseIterable, Identifiable {
    case deep
    case solid
    case stub

    var id: String { rawValue }
}

enum RhythmRegion: String, CaseIterable, Identifiable {
    case all
    case globalElectronic
    case uk
    case caribbeanLatin
    case brazil
    case afroCuban
    case northAmerica
    case jazzTradition
    case world

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .globalElectronic: "Global Electronic"
        case .uk: "UK"
        case .caribbeanLatin: "Caribbean / Latin"
        case .brazil: "Brazil"
        case .afroCuban: "Afro-Cuban"
        case .northAmerica: "North America"
        case .jazzTradition: "Jazz Traditions"
        case .world: "World"
        }
    }

    var subtitle: String {
        switch self {
        case .all: "Every rhythm in the library"
        case .globalElectronic: "Club patterns and drum-machine lineages"
        case .uk: "Garage, breakbeat, and UK dance forms"
        case .caribbeanLatin: "Cumbia, dembow, and adjacent grooves"
        case .brazil: "Brazilian pulse, clave-like phrasing, and sway"
        case .afroCuban: "Timeline-driven rhythmic structures"
        case .northAmerica: "Hip-hop, breakbeats, and modern pop backbeats"
        case .jazzTradition: "Ride-led flow, swing, and ensemble time"
        case .world: "Meters and traditions for later expansion"
        }
    }
}

enum LaneSlot: String, CaseIterable, Identifiable {
    case pulse
    case lowDrum
    case backbeatHand
    case closedHigh
    case openHigh
    case timeline
    case texture
    case aux1
    case aux2

    var id: String { rawValue }
}

enum SharedLineRole: String, CaseIterable, Hashable, Identifiable {
    case guide
    case foundation
    case frame
    case counterline
    case timekeeper
    case lift
    case timeline
    case commentary

    var id: String { rawValue }
}

enum InstrumentVoice: String, Hashable {
    case click
    case kick
    case snare
    case clap
    case crossStick
    case closedHat
    case openHat
    case hiHatFoot
    case ride
    case brushTap
    case brushSweep
    case shaker
    case maraca
    case guache
    case clave
    case agogo
    case tambora
    case llamador
    case alegre
    case surdo
    case pandeiro
    case tamborim
    case caixa
    case congaLow
}

enum LaneTimingProfile: String, Hashable {
    case laidBackOffbeat
    case shuffledSixteenth

    func offsetMultiplier(subdivisionIndex: Int, stepsPerPulse: Int) -> Double {
        switch self {
        case .laidBackOffbeat:
            guard stepsPerPulse == 4 else { return 0 }
            return subdivisionIndex == 2 ? 1.0 : 0
        case .shuffledSixteenth:
            guard stepsPerPulse == 4 else { return 0 }
            switch subdivisionIndex {
            case 1, 3:
                return 0.35
            case 2:
                return 1.0
            default:
                return 0
            }
        }
    }
}

struct LaneTiming: Hashable {
    let profile: LaneTimingProfile
    let amountMultiplier: Double

    init(profile: LaneTimingProfile, amountMultiplier: Double = 1.0) {
        self.profile = profile
        self.amountMultiplier = amountMultiplier
    }

    func stepOffset(for step: Int, in cycle: RhythmCycle, swingAmount: Double) -> Double {
        let clampedSwingAmount = min(max(swingAmount, 0), 1)
        let subdivisionIndex = step % cycle.stepsPerPulse
        let multiplier = profile.offsetMultiplier(
            subdivisionIndex: subdivisionIndex,
            stepsPerPulse: cycle.stepsPerPulse
        )
        return multiplier * amountMultiplier * clampedSwingAmount
    }
}

struct StepEvent: Hashable {
    let step: Int
    let intensity: Double
    let isAccent: Bool
}

struct RhythmLane: Identifiable, Hashable {
    let id: String
    let slot: LaneSlot
    let role: SharedLineRole
    let instrument: String
    let note: String?
    let voice: InstrumentVoice
    let timing: LaneTiming?
    let events: [StepEvent]

    func event(at step: Int) -> StepEvent? {
        events.first { $0.step == step }
    }

    func stepOffset(at step: Int, in cycle: RhythmCycle, swingAmount: Double) -> Double {
        timing?.stepOffset(for: step, in: cycle, swingAmount: swingAmount) ?? 0
    }
}

struct RhythmVariant: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let hearingFocus: String
    let swingAmount: Double
    let backbeatGuideHostLaneID: String?
    let accentGuideHostLaneID: String?
    let lanes: [RhythmLane]

    init(
        id: String,
        name: String,
        summary: String,
        hearingFocus: String,
        swingAmount: Double,
        backbeatGuideHostLaneID: String? = nil,
        accentGuideHostLaneID: String? = nil,
        lanes: [RhythmLane]
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.hearingFocus = hearingFocus
        self.swingAmount = swingAmount
        self.backbeatGuideHostLaneID = backbeatGuideHostLaneID
        self.accentGuideHostLaneID = accentGuideHostLaneID
        self.lanes = lanes
    }
}

struct RhythmCycle: Identifiable, Hashable {
    let id: String
    let meter: String
    let pulseLabels: [String]
    let subdivisionLabels: [String]
    let barBreakPulseIndices: [Int]
    let pulseUnitName: String
    let stepUnitName: String
    let nativeFeel: String

    var pulseCount: Int { pulseLabels.count }
    var stepCount: Int { pulseLabels.count * subdivisionLabels.count }
    var stepsPerPulse: Int { subdivisionLabels.count }
    var barCount: Int { barBreakPulseIndices.count }

    func label(for step: Int) -> String {
        let subdivisionIndex = step % subdivisionLabels.count
        if subdivisionIndex == 0 {
            return pulseLabels[step / subdivisionLabels.count]
        }
        return subdivisionLabels[subdivisionIndex]
    }

    func isPulseStart(_ step: Int) -> Bool {
        step % subdivisionLabels.count == 0
    }

    func isBarBreak(after step: Int) -> Bool {
        let subdivisionIndex = step % subdivisionLabels.count
        guard subdivisionIndex == subdivisionLabels.count - 1 else { return false }
        let pulseIndex = step / subdivisionLabels.count
        return barBreakPulseIndices.contains(pulseIndex)
    }

    func durationPerStep(at bpm: Double) -> TimeInterval {
        60.0 / bpm / Double(subdivisionLabels.count)
    }
}

struct RhythmDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let alternateName: String?
    let tradition: String
    let family: String
    let region: RhythmRegion
    let tier: RhythmTier
    let summary: String
    let hearingCue: String
    let feelKeywords: [String]
    let cycle: RhythmCycle
    let defaultTempo: Double
    let tempoRange: ClosedRange<Double>
    let variants: [RhythmVariant]
    let teachingOverlays: [String]
    let notes: [String]

    var defaultVariant: RhythmVariant {
        variants[0]
    }

    var preferredTempo: Double {
        defaultTempo
    }
}

extension LaneSlot {
    var defaultSharedRole: SharedLineRole {
        switch self {
        case .pulse: .guide
        case .lowDrum: .foundation
        case .backbeatHand: .frame
        case .closedHigh: .timekeeper
        case .openHigh: .lift
        case .timeline: .timeline
        case .texture: .timekeeper
        case .aux1, .aux2: .commentary
        }
    }
}
