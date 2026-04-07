import Foundation

enum RhythmDatabase {
    static let all: [RhythmDefinition] = [
        cumbia,
        bossaNova,
        classicTechno,
        twoStep,
        samba,
        sonClave,
        boomBap,
        jazzRideSwing,
        dembow,
        jazzWaltz
    ]

    private static let fourFourSixteenth = RhythmCycle(
        id: "4-4-sixteenth",
        meter: "4/4",
        pulseLabels: ["1", "2", "3", "4"],
        subdivisionLabels: ["", "e", "&", "a"],
        barBreakPulseIndices: [3],
        pulseUnitName: "Quarter note",
        stepUnitName: "Sixteenth note",
        nativeFeel: "Straight 16ths"
    )

    private static let twoBarFourFourSixteenth = RhythmCycle(
        id: "2-bar-4-4-sixteenth",
        meter: "4/4 over 2 bars",
        pulseLabels: ["1", "2", "3", "4", "1", "2", "3", "4"],
        subdivisionLabels: ["", "e", "&", "a"],
        barBreakPulseIndices: [3, 7],
        pulseUnitName: "Quarter note",
        stepUnitName: "Sixteenth note",
        nativeFeel: "Phrased across a two-bar cycle"
    )

    private static let twelveEight = RhythmCycle(
        id: "12-8",
        meter: "12/8",
        pulseLabels: ["1", "2", "3", "4"],
        subdivisionLabels: ["", "&", "a"],
        barBreakPulseIndices: [3],
        pulseUnitName: "Dotted quarter",
        stepUnitName: "Eighth-note triplet",
        nativeFeel: "Compound pulse"
    )

    private static let threeFourSwing = RhythmCycle(
        id: "3-4-triplet",
        meter: "3/4",
        pulseLabels: ["1", "2", "3"],
        subdivisionLabels: ["", "&", "a", "let"],
        barBreakPulseIndices: [2],
        pulseUnitName: "Quarter note",
        stepUnitName: "Subdivided quarter",
        nativeFeel: "Triple meter with flowing subdivision"
    )

    private static let cumbia = RhythmDefinition(
        id: "cumbia",
        name: "Cumbia",
        alternateName: "Basic Colombian cumbia adaptation",
        tradition: "Colombia",
        family: "Cumbia",
        region: .caribbeanLatin,
        tier: .deep,
        summary: "A layered groove built from tambora, llamador, and maraca roles, adapted here into a shared drum-lane model.",
        hearingCue: "Hear the offbeat pull in the hand part against a grounded low drum and constant shaker flow.",
        feelKeywords: ["Grounded", "Circular", "Offbeat lift", "Dance pulse"],
        cycle: fourFourSixteenth,
        defaultTempo: 92,
        tempoRange: 84...102,
        variants: [
            RhythmVariant(
                id: "cumbia-canonical",
                name: "Core Dance Pulse",
                summary: "A role-based adaptation emphasizing tambora weight, llamador offbeats, and continuous maraca.",
                hearingFocus: "Lock to the shaker first, then notice how the hand line answers on beats 2 and 4.",
                swingAmount: 0.08,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Tambora", .lowTom, [0, 6, 8, 10], accents: [0, 8]),
                    lane("hand", .backbeatHand, "Llamador", .snare, [4, 12], accents: [4, 12]),
                    lane("texture", .texture, "Maraca", .shaker, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14]),
                    lane("aux1", .aux1, "Alegre response", .midTom, [7, 15], accents: [15])
                ]
            ),
            RhythmVariant(
                id: "cumbia-modern-kit",
                name: "Kit Translation",
                summary: "A slightly more drum-set-shaped version that still keeps the cumbia push on the offbeats.",
                hearingFocus: "The groove stays cumbia because the hand line and shaker logic remain intact even when the low drum is simplified.",
                swingAmount: 0.06,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick / Tambora", .kick, [0, 6, 8, 10], accents: [0, 8]),
                    lane("hand", .backbeatHand, "Caja / Hand", .snare, [4, 12], accents: [4, 12]),
                    lane("texture", .texture, "Guache / Maraca", .shaker, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14]),
                    lane("closed", .closedHigh, "Closed metal", .closedHat, [3, 7, 11, 15], accents: [7, 15])
                ]
            )
        ],
        teachingOverlays: [
            "Show quarter-note pulse markers",
            "Shade beats 2 and 4 where the hand line answers",
            "Emphasize the continuous shaker lane as the continuity layer"
        ],
        notes: [
            "This is a pedagogical adaptation of layered cumbia roles into a common lane system, not a claim that one fixed drum chart defines the tradition.",
            "The low drum and hand parts are intentionally separated so the learner can hear the conversation between weight and lift."
        ]
    )

    private static let bossaNova = RhythmDefinition(
        id: "bossa-nova",
        name: "Bossa Nova",
        alternateName: "Drum-set adaptation",
        tradition: "Brazil",
        family: "Bossa Nova",
        region: .brazil,
        tier: .deep,
        summary: "A quiet, interlocking two-bar groove where bass-drum placement and side-stick phrasing create a soft forward lean.",
        hearingCue: "Hear the two-bar phrase as one long breath: the low drum guides the floor while the side-stick shapes the syncopation.",
        feelKeywords: ["Two-bar phrase", "Supple", "Subtle syncopation", "Floating"],
        cycle: twoBarFourFourSixteenth,
        defaultTempo: 138,
        tempoRange: 124...152,
        variants: [
            RhythmVariant(
                id: "bossa-canonical",
                name: "Soft Kit Ostinato",
                summary: "A common drum-set reduction of bossa nova, stretched over two bars so the phrase can actually read as a phrase.",
                hearingFocus: "Do not hear this bar by bar. The identity lives in how the side-stick and low drum complete each other across two bars.",
                swingAmount: 0.02,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("low", .lowDrum, "Surdo / Kick", .kick, [0, 10, 16, 26], accents: [0, 16]),
                    lane("hand", .backbeatHand, "Side stick", .clave, [3, 6, 10, 14, 19, 22, 26, 30], accents: [3, 10, 19, 26]),
                    lane("texture", .texture, "Shaker / hat", .shaker, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [2, 6, 10, 14, 18, 22, 26, 30])
                ]
            ),
            RhythmVariant(
                id: "bossa-ride",
                name: "Ride-led Drift",
                summary: "The same phrase with the high layer opened up, making the internal syncopation easier to trace.",
                hearingFocus: "Follow the high lane first, then listen to where the side-stick deliberately refuses a simple 2-and-4 reading.",
                swingAmount: 0.02,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("low", .lowDrum, "Surdo / Kick", .kick, [0, 10, 16, 26], accents: [0, 16]),
                    lane("hand", .backbeatHand, "Side stick", .clave, [3, 6, 10, 14, 19, 22, 26, 30], accents: [3, 10, 19, 26]),
                    lane("closed", .closedHigh, "Closed cymbal", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [4, 12, 20, 28]),
                    lane("open", .openHigh, "Open cymbal", .openHat, [15, 31], accents: [15, 31])
                ]
            )
        ],
        teachingOverlays: [
            "Draw a bar divider between steps 15 and 16",
            "Highlight the low-drum phrase across both bars",
            "Show the side-stick as the main syncopation contour"
        ],
        notes: [
            "The two-bar view matters here. Compressing the groove to one generic 16-step bar would hide too much of the phrase logic.",
            "This entry focuses on a widely used drum-set translation rather than a full ensemble transcription."
        ]
    )

    private static let classicTechno = RhythmDefinition(
        id: "classic-techno",
        name: "Classic Techno 4/4",
        alternateName: "Warehouse pulse",
        tradition: "Global club lineage",
        family: "Techno",
        region: .globalElectronic,
        tier: .deep,
        summary: "The canonical machine-grid logic: four-on-the-floor weight, backbeat reinforcement, and offbeat air.",
        hearingCue: "Feel the quarter-note floor first. Everything else is propulsion built around that certainty.",
        feelKeywords: ["Machine-grid", "Driving", "Relentless", "Offbeat air"],
        cycle: fourFourSixteenth,
        defaultTempo: 134,
        tempoRange: 128...140,
        variants: [
            RhythmVariant(
                id: "techno-core",
                name: "Warehouse Core",
                summary: "The foundational pattern: kick on all four beats, clap on 2 and 4, and a single offbeat high layer.",
                hearingFocus: "The groove is not complicated. The force comes from hearing the empty space between the floor kicks and the offbeat top line.",
                swingAmount: 0,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("hand", .backbeatHand, "Clap", .snare, [4, 12], accents: [4, 12]),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14])
                ]
            ),
            RhythmVariant(
                id: "techno-driving-hats",
                name: "Driving Hats",
                summary: "Adds a constant closed hat so the offbeat openings feel suspended over a denser rail.",
                hearingFocus: "Hear the open hat as a breath on the offbeats and the closed hat as the motor underneath it.",
                swingAmount: 0,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("hand", .backbeatHand, "Clap", .snare, [4, 12], accents: [4, 12]),
                    lane("closed", .closedHigh, "Closed hat", .closedHat, Array(0..<16), accents: [2, 6, 10, 14]),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14])
                ]
            )
        ],
        teachingOverlays: [
            "Highlight all quarter-note kicks as the anchor layer",
            "Show offbeat top-lane positions in a distinct color",
            "Let the user mute the clap to hear how much of the identity still survives"
        ],
        notes: [
            "The point here is not complexity. It is hearing how a simple machine grid becomes forceful through repetition, air, and placement.",
            "This entry treats classic techno as a groove family rather than a single production recipe."
        ]
    )

    private static let twoStep = RhythmDefinition(
        id: "two-step",
        name: "2-Step Garage",
        alternateName: "UK garage core",
        tradition: "UK",
        family: "UK Garage",
        region: .uk,
        tier: .deep,
        summary: "A syncopated UK garage groove where the missing floor-kick pulse creates buoyancy, gaps, and forward pull.",
        hearingCue: "Hear the snare frame on 2 and 4, then notice how the kick refuses to fill in a simple house grid.",
        feelKeywords: ["Skippy", "Shuffled", "Syncopated", "Elastic"],
        cycle: fourFourSixteenth,
        defaultTempo: 132,
        tempoRange: 128...136,
        variants: [
            RhythmVariant(
                id: "two-step-core",
                name: "Skippy Core",
                summary: "The kicks are displaced so the groove breathes around the snare frame instead of locking into four-on-the-floor.",
                hearingFocus: "Listen for the gaps. The absence of a floor kick is part of the pattern, not missing information.",
                swingAmount: 0.18,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 11], accents: [0, 11]),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12]),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14]),
                    lane("texture", .texture, "Shaker ghosts", .shaker, [3, 7, 15], accents: [7, 15])
                ]
            ),
            RhythmVariant(
                id: "two-step-airy",
                name: "Airy Shuffle",
                summary: "A slightly more open top line that makes the kick displacement easier to hear.",
                hearingFocus: "The high layer keeps time, but the identity still comes from how the kicks dodge the house-grid expectation.",
                swingAmount: 0.22,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 11], accents: [0, 11]),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12]),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14]),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15]),
                    lane("texture", .texture, "Ghosts", .shaker, [3, 5, 13], accents: [5, 13])
                ]
            )
        ],
        teachingOverlays: [
            "Show the house-grid quarter-note expectation behind the actual kick placements",
            "Highlight missing floor-kick positions as negative space",
            "Mark swung high-lane steps differently from straight grid steps"
        ],
        notes: [
            "This is a canonical 2-step learning groove rather than a transcription of one record.",
            "The user should be able to mute the hats and still hear the snare frame plus displaced kicks as the main identity."
        ]
    )

    private static let samba = RhythmDefinition(
        id: "samba",
        name: "Samba",
        alternateName: "Basic samba kit adaptation",
        tradition: "Brazil",
        family: "Samba",
        region: .brazil,
        tier: .solid,
        summary: "A fast Brazilian pulse with low-drum propulsion and a more continuous top texture than bossa nova.",
        hearingCue: "Feel the rolling low-end pulse and the steadier surface shimmer.",
        feelKeywords: ["Continuous", "Forward", "Carnival pulse"],
        cycle: fourFourSixteenth,
        defaultTempo: 102,
        tempoRange: 96...116,
        variants: [
            RhythmVariant(
                id: "samba-core",
                name: "Basic Kit Samba",
                summary: "A starter view of samba propulsion in the shared lane model.",
                hearingFocus: "Follow the low drum and texture lanes together.",
                swingAmount: 0.03,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Surdo / Kick", .kick, [0, 3, 8, 11], accents: [0, 8]),
                    lane("hand", .backbeatHand, "Cross-stick", .clave, [4, 12], accents: [4, 12]),
                    lane("texture", .texture, "Tamborim / shaker", .shaker, Array(stride(from: 0, to: 16, by: 2)), accents: [2, 6, 10, 14])
                ]
            )
        ],
        teachingOverlays: [
            "Keep the pulse visible while the low drum moves around it"
        ],
        notes: [
            "This solid-tier entry exists as a bridge outward from bossa nova."
        ]
    )

    private static let sonClave = RhythmDefinition(
        id: "son-clave",
        name: "Son Clave",
        alternateName: "3-2 orientation",
        tradition: "Afro-Cuban",
        family: "Clave",
        region: .afroCuban,
        tier: .solid,
        summary: "A timeline groove where the clave line acts as structural reference rather than decoration.",
        hearingCue: "Hear the clave as orientation. The other lanes exist around it.",
        feelKeywords: ["Timeline", "Reference pattern", "Orientation"],
        cycle: twoBarFourFourSixteenth,
        defaultTempo: 98,
        tempoRange: 90...110,
        variants: [
            RhythmVariant(
                id: "son-3-2",
                name: "3-2 Son Clave",
                summary: "A timeline-first entry so the library can explain clave-based hearing later.",
                hearingFocus: "The clave is the map. Count the rest against it.",
                swingAmount: 0.04,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("timeline", .timeline, "Clave", .clave, [0, 6, 12, 18, 24], accents: [0, 6, 12, 18, 24]),
                    lane("low", .lowDrum, "Tumbao support", .lowTom, [0, 10, 16, 26], accents: [10, 26]),
                    lane("texture", .texture, "Shaker", .shaker, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [2, 6, 10, 14, 18, 22, 26, 30])
                ]
            )
        ],
        teachingOverlays: [
            "Display the timeline lane in a dedicated color"
        ],
        notes: [
            "This is included so the app can later make stronger rhythm-family comparisons without introducing those comparisons in v1."
        ]
    )

    private static let boomBap = RhythmDefinition(
        id: "boom-bap",
        name: "Boom Bap",
        alternateName: nil,
        tradition: "US hip-hop",
        family: "Hip-Hop",
        region: .northAmerica,
        tier: .solid,
        summary: "A backbeat-led groove where the kick and snare frame define the pocket and the hats sit slightly on top.",
        hearingCue: "Hear the snare as the center of the groove, not just a marker.",
        feelKeywords: ["Backbeat", "Pocket", "Head-nod"],
        cycle: fourFourSixteenth,
        defaultTempo: 92,
        tempoRange: 84...98,
        variants: [
            RhythmVariant(
                id: "boom-bap-core",
                name: "Core Loop",
                summary: "A starter hip-hop pocket with kick setup and snare response.",
                hearingFocus: "The kick leads into the snare rather than replacing the pulse.",
                swingAmount: 0.1,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 7, 10], accents: [0, 10]),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12]),
                    lane("closed", .closedHigh, "Hat", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14])
                ]
            )
        ],
        teachingOverlays: [
            "Show strong backbeats against a relaxed high layer"
        ],
        notes: [
            "Included as a support genre for later breadth."
        ]
    )

    private static let jazzRideSwing = RhythmDefinition(
        id: "jazz-ride",
        name: "Jazz Ride Swing",
        alternateName: nil,
        tradition: "Jazz",
        family: "Swing",
        region: .jazzTradition,
        tier: .solid,
        summary: "A ride-led swing pattern where the cymbal line carries the time and the low drum stays mostly referential.",
        hearingCue: "Hear the ride cymbal as the real clock.",
        feelKeywords: ["Ride-led", "Swing", "Lift"],
        cycle: twelveEight,
        defaultTempo: 148,
        tempoRange: 132...176,
        variants: [
            RhythmVariant(
                id: "jazz-ride-core",
                name: "Ride Cymbal Time",
                summary: "A compound-grid rendering of jazz swing for the cycle view.",
                hearingFocus: "The skipped middle subdivision is where the bounce lives.",
                swingAmount: 0.2,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 3, 6, 9], accents: [0, 3, 6, 9]),
                    lane("closed", .closedHigh, "Ride", .bell, [0, 2, 3, 5, 6, 8, 9, 11], accents: [0, 3, 6, 9]),
                    lane("hand", .backbeatHand, "Hi-hat foot", .closedHat, [3, 9], accents: [3, 9]),
                    lane("low", .lowDrum, "Feathered kick", .kick, [0, 3, 6, 9], accents: [0, 3, 6, 9])
                ]
            )
        ],
        teachingOverlays: [
            "Render triplet subdivision labels clearly"
        ],
        notes: [
            "This solid entry demonstrates why the app needs cycle types beyond a fixed 16-step square."
        ]
    )

    private static let dembow = RhythmDefinition(
        id: "dembow",
        name: "Dembow",
        alternateName: nil,
        tradition: "Caribbean",
        family: "Dembow",
        region: .caribbeanLatin,
        tier: .stub,
        summary: "A clipped, heavily legible reggaeton backbone.",
        hearingCue: "Hear the kick-snare alternation as a repeating statement.",
        feelKeywords: ["Direct", "Looping"],
        cycle: fourFourSixteenth,
        defaultTempo: 96,
        tempoRange: 88...104,
        variants: [
            RhythmVariant(
                id: "dembow-core",
                name: "Core Loop",
                summary: "A stub entry for later expansion.",
                hearingFocus: "This exists primarily to make the library broader in v1.",
                swingAmount: 0,
                lanes: [
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 8, 11], accents: [0, 8]),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 10, 12], accents: [4, 12]),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14])
                ]
            )
        ],
        teachingOverlays: [],
        notes: [
            "Stub entry."
        ]
    )

    private static let jazzWaltz = RhythmDefinition(
        id: "jazz-waltz",
        name: "Jazz Waltz",
        alternateName: nil,
        tradition: "Jazz",
        family: "Waltz",
        region: .jazzTradition,
        tier: .stub,
        summary: "Triple-meter swing scaffolding for later expansion.",
        hearingCue: "Hear the ride pattern cycling through three, not four.",
        feelKeywords: ["Triple meter", "Flowing"],
        cycle: threeFourSwing,
        defaultTempo: 150,
        tempoRange: 132...168,
        variants: [
            RhythmVariant(
                id: "jazz-waltz-core",
                name: "Core Time",
                summary: "A stub to prove the cycle renderer can leave four-square logic behind.",
                hearingFocus: "Let the repeating groups of three settle before listening for accents.",
                swingAmount: 0.12,
                lanes: [
                    lane("pulse", .pulse, "Count", .click, [0, 4, 8], accents: [0, 4, 8]),
                    lane("closed", .closedHigh, "Ride", .bell, [0, 3, 4, 7, 8, 11], accents: [0, 4, 8]),
                    lane("hand", .backbeatHand, "Hi-hat foot", .closedHat, [4, 8], accents: [4, 8])
                ]
            )
        ],
        teachingOverlays: [],
        notes: [
            "Stub entry."
        ]
    )

    private static func lane(
        _ id: String,
        _ role: LaneRole,
        _ label: String,
        _ voice: InstrumentVoice,
        _ hits: [Int],
        accents: Set<Int> = []
    ) -> RhythmLane {
        RhythmLane(
            id: id,
            role: role,
            label: label,
            voice: voice,
            events: hits.sorted().map { step in
                StepEvent(
                    step: step,
                    intensity: accents.contains(step) ? 1.0 : 0.72,
                    isAccent: accents.contains(step)
                )
            }
        )
    }
}
