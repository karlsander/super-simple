import Foundation

enum RhythmDatabase {
    static let all: [RhythmDefinition] = [
        cumbia,
        bossaNova,
        classicTechno,
        twoStep,
        houseCore,
        fourByFourGarage,
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
        summary: "A layered cumbia foundation built from tambora, llamador, and maraca roles, adapted here into a shared lane model without flattening the feel into generic kick-snare-hat logic.",
        hearingCue: "Hear the maraca as continuity, the tambora as weight, and the llamador as the answer that gives the groove its lift.",
        feelKeywords: ["Grounded", "Circular", "Offbeat lift", "Dance pulse"],
        cycle: fourFourSixteenth,
        defaultTempo: 92,
        tempoRange: 84...102,
        variants: [
            RhythmVariant(
                id: "cumbia-foundation",
                name: "Basic",
                summary: "The three fixed layers only: tambora, llamador, and maraca, with no extra response drum clouding the basic identity.",
                hearingFocus: "Start with the maraca pulse, then feel how the llamador answers against that flow rather than simply backbeating like pop.",
                swingAmount: 0.08,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane(
                        "low",
                        .lowDrum,
                        "Tambora",
                        .tambora,
                        [0, 6, 8, 10],
                        accents: [0, 8],
                        note: "Low circular weight. This is the floor."
                    ),
                    lane(
                        "hand",
                        .backbeatHand,
                        "Llamador",
                        .llamador,
                        [4, 12],
                        accents: [4, 12],
                        role: .counterline,
                        note: "Short answer line. More reply than backbeat."
                    ),
                    lane(
                        "texture",
                        .texture,
                        "Maraca",
                        .maraca,
                        [0, 2, 4, 6, 8, 10, 12, 14],
                        accents: [2, 6, 10, 14],
                        note: "Keeps the dance pulse audible between drum hits."
                    )
                ]
            ),
            RhythmVariant(
                id: "cumbia-canonical",
                name: "Alegre Response",
                summary: "Adds a light improvised-response role on top of the fixed cumbia layers, making the ensemble feel more alive without changing the foundation.",
                hearingFocus: "The identity should still be obvious when you ignore the response drum. If it is not, the foundation is not clear enough yet.",
                swingAmount: 0.08,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Tambora", .tambora, [0, 6, 8, 10], accents: [0, 8], note: "Low circular weight. This is the floor."),
                    lane("hand", .backbeatHand, "Llamador", .llamador, [4, 12], accents: [4, 12], role: .counterline, note: "Short answer line. More reply than backbeat."),
                    lane("texture", .texture, "Maraca", .maraca, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], note: "Keeps the dance pulse audible between drum hits."),
                    lane(
                        "aux1",
                        .aux1,
                        "Alegre",
                        .alegre,
                        [7, 11, 15],
                        accents: [15],
                        note: "Free response on top of the fixed layers."
                    )
                ]
            ),
            RhythmVariant(
                id: "cumbia-modern-kit",
                name: "Kit Translation",
                summary: "A more drum-set-shaped rendering that still keeps the cumbia pull by preserving the hand-answer and continuity layer.",
                hearingFocus: "If this starts to feel like a generic Latin-pop beat, listen for the hand-answer and shaker continuity again.",
                swingAmount: 0.06,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane(
                        "low",
                        .lowDrum,
                        "Kick drum",
                        .kick,
                        [0, 6, 8, 10],
                        accents: [0, 8],
                        note: "Tambora shape, translated to kick drum."
                    ),
                    lane(
                        "hand",
                        .backbeatHand,
                        "Cross-stick answer",
                        .crossStick,
                        [4, 12],
                        accents: [4, 12],
                        role: .counterline
                    ),
                    lane("texture", .texture, "Guache", .guache, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14]),
                    lane("closed", .closedHigh, "Closed metal", .closedHat, [3, 7, 11, 15], accents: [7, 15], role: .lift)
                ]
            )
        ],
        teachingOverlays: [
            "Show quarter-note pulse markers",
            "Shade beats 2 and 4 where the hand line answers",
            "Emphasize the continuous shaker lane as the continuity layer",
            "Keep the fixed layers legible before adding the alegre response"
        ],
        notes: [
            "This entry follows the Carnegie Hall teaching framing that cumbia is heard as layered tambora, llamador, and maraca parts, with alegre improvising over the top.",
            "This is still a pedagogical adaptation into shared lanes, not a claim that one fixed drum chart defines all cumbia."
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
        summary: "A quiet, interlocking two-bar groove whose identity comes from phrase length, low-drum placement, and the soft syncopation contour of the side-stick.",
        hearingCue: "Do not hear it as a bar-long pop beat. Hear the two bars as one breath, with the side-stick tracing the shape and the low drum implying surdo logic.",
        feelKeywords: ["Two-bar phrase", "Supple", "Subtle syncopation", "Floating"],
        cycle: twoBarFourFourSixteenth,
        defaultTempo: 132,
        tempoRange: 116...148,
        variants: [
            RhythmVariant(
                id: "bossa-canonical",
                name: "Basic",
                summary: "The stripped bossa argument: low-drum phrase plus side-stick contour across two bars, with no extra texture hiding the relationship.",
                hearingFocus: "Hear the low drum and side-stick as one two-bar sentence. If you reduce it to a one-bar backbeat, the style disappears.",
                swingAmount: 0.02,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane(
                        "low",
                        .lowDrum,
                        "Surdo",
                        .surdo,
                        [0, 10, 16, 22, 26],
                        accents: [0, 16],
                        note: "Two-bar low phrase. Hear both bars as one breath."
                    ),
                    lane(
                        "hand",
                        .backbeatHand,
                        "Cross-stick",
                        .crossStick,
                        [3, 6, 10, 14, 19, 22, 26, 30],
                        accents: [3, 10, 19, 26],
                        role: .counterline,
                        note: "Side-stick contour across the whole phrase."
                    )
                ]
            ),
            RhythmVariant(
                id: "bossa-shaker",
                name: "Shaker Flow",
                summary: "Adds the quiet surface motion that lets the two-bar phrase breathe without turning the groove into a busier Latin pattern.",
                hearingFocus: "The shaker should support the phrase, not distract from it. The identity still lives in the low drum and side-stick contour.",
                swingAmount: 0.02,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 10, 16, 22, 26], accents: [0, 16], note: "Two-bar low phrase. Hear both bars as one breath."),
                    lane("hand", .backbeatHand, "Cross-stick", .crossStick, [3, 6, 10, 14, 19, 22, 26, 30], accents: [3, 10, 19, 26], role: .counterline, note: "Side-stick contour across the whole phrase."),
                    lane("texture", .texture, "Shaker", .shaker, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [2, 6, 10, 14, 18, 22, 26, 30], note: "Quiet surface motion so the phrase can breathe.")
                ]
            ),
            RhythmVariant(
                id: "bossa-brushes",
                name: "Brush Clave",
                summary: "A brush-led charting of the same phrase, pulling the left-hand contour closer to a clave-like timekeeping role.",
                hearingFocus: "The side-hand pattern is not a rock backbeat. It is a contour against the two-bar phrase.",
                swingAmount: 0.02,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 10, 16, 22, 26], accents: [0, 16], note: "Two-bar low phrase. Hear both bars as one breath."),
                    lane("hand", .backbeatHand, "Brush tap", .brushTap, [3, 6, 10, 14, 19, 22, 26, 30], accents: [3, 10, 19, 26], role: .counterline, note: "Same contour, just brushed."),
                    lane(
                        "texture",
                        .texture,
                        "Brush sweep",
                        .brushSweep,
                        [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
                        accents: [0, 8, 16, 24],
                        note: "Connects the air between the taps."
                    )
                ]
            ),
            RhythmVariant(
                id: "bossa-ride",
                name: "Ride-led Drift",
                summary: "The same phrase with the top layer more exposed, making the underlying syncopation easier to hear.",
                hearingFocus: "Follow the top line first, then hear how the side-stick deliberately avoids a simple 2-and-4 backbeat reading.",
                swingAmount: 0.02,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 10, 16, 22, 26], accents: [0, 16], note: "Two-bar low phrase. Hear both bars as one breath."),
                    lane("hand", .backbeatHand, "Cross-stick", .crossStick, [3, 6, 10, 14, 19, 22, 26, 30], accents: [3, 10, 19, 26], role: .counterline, note: "Side-stick contour across the whole phrase."),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [4, 12, 20, 28], note: "Puts the phrase on top without changing it."),
                    lane("open", .openHigh, "Open cymbal", .openHat, [15, 31], accents: [15, 31])
                ]
            )
        ],
        teachingOverlays: [
            "Draw a bar divider between steps 15 and 16",
            "Highlight the low-drum phrase across both bars",
            "Show the side-stick as the main syncopation contour",
            "Keep the subdivision straight so the phrase breathes instead of shuffling"
        ],
        notes: [
            "The two-bar view matters here. Compressing the groove to one generic 16-step bar hides the phrase logic.",
            "The Nebraska jazz drum-set material was useful for validating that bossa time is commonly taught as a two-measure suggestion rather than a one-bar loop."
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
        summary: "The canonical machine-grid logic: four-on-the-floor weight, backbeat reinforcement, and offbeat air, with small hi-hat changes doing far more than extra note-count ever could.",
        hearingCue: "Feel the quarter-note floor first. Everything else is propulsion built around that certainty, not a replacement for it.",
        feelKeywords: ["Machine-grid", "Driving", "Relentless", "Offbeat air"],
        cycle: fourFourSixteenth,
        defaultTempo: 134,
        tempoRange: 128...140,
        variants: [
            RhythmVariant(
                id: "techno-core",
                name: "Basic",
                summary: "Just the non-negotiable floor kick and the offbeat high answer. If those two lines do not feel like techno yet, adding more notes will not fix it.",
                hearingFocus: "Feel the four-on-the-floor weight first, then hear the offbeat hat as the air between the kicks.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "low",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "The floor. Everything else hangs off it."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Offbeat air between the floor kicks.")
                ]
            ),
            RhythmVariant(
                id: "techno-clap-frame",
                name: "Clap Frame",
                summary: "Adds the simplest backbeat reinforcement without changing the underlying four-floor and offbeat-hat logic.",
                hearingFocus: "The clap adds pressure, but the groove still lives in the kick and offbeat hat relationship.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "The floor. Everything else hangs off it."),
                    lane("hand", .backbeatHand, "Clap", .clap, [4, 12], accents: [4, 12], note: "Pressure frame on 2 and 4."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Offbeat air between the floor kicks.")
                ]
            ),
            RhythmVariant(
                id: "techno-driving-hats",
                name: "Belleville Drive",
                summary: "Adds denser hats and a touch of looseness so the groove breathes without abandoning the machine-grid certainty.",
                hearingFocus: "Hear the offbeat hat as the breath, the 16th hats as the motor, and the kick as the thing that never negotiates.",
                swingAmount: 0.08,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "The floor. Everything else hangs off it."),
                    lane("hand", .backbeatHand, "Clap", .clap, [4, 12], accents: [4, 12], note: "Pressure frame on 2 and 4."),
                    lane("closed", .closedHigh, "Closed hat", .closedHat, [1, 2, 5, 6, 9, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(0.55), note: "Sixteenth-note motor."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(0.85), note: "Offbeat air between the floor kicks."),
                    lane("texture", .texture, "Mid hat", .closedHat, [0, 4, 8, 12], accents: [4, 12], role: .commentary, note: "Extra grain without blurring the grid.")
                ]
            )
        ],
        teachingOverlays: [
            "Highlight all quarter-note kicks as the anchor layer",
            "Show offbeat top-lane positions in a distinct color",
            "Let the user mute the clap to hear how much of the identity still survives",
            "Show that minor hat variations change propulsion without changing the kick argument"
        ],
        notes: [
            "Attack Magazine's Belleville-techno walkthrough was useful here: the underlying lesson is efficiency, 909-derived weight, and lightly swung hat detail rather than maximal drum density.",
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
        summary: "A syncopated UK garage groove where missing or displaced floor kicks create buoyancy, hesitations, and the sense that the beat keeps inhaling and skipping forward.",
        hearingCue: "Hear the snare frame first, then hear how the kicks dodge the house-grid expectation while the high layers keep the body moving.",
        feelKeywords: ["Skippy", "Shuffled", "Syncopated", "Elastic"],
        cycle: fourFourSixteenth,
        defaultTempo: 132,
        tempoRange: 127...135,
        variants: [
            RhythmVariant(
                id: "two-step-core",
                name: "Basic",
                summary: "The minimum 2-step argument: displaced kick, snare frame, and a shuffled high line that keeps the body moving through the gaps.",
                hearingFocus: "Listen for the missing floor kicks. The holes are part of the groove, not missing information.",
                swingAmount: 0.20,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 11], accents: [0, 11], note: "The missing floor kicks are the point."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Keeps 2 and 4 in your body."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Shuffled glue through the gaps.")
                ]
            ),
            RhythmVariant(
                id: "two-step-ghosted",
                name: "Ghosted Skips",
                summary: "Adds quieter between-beat events so the groove feels elastic rather than merely sparse.",
                hearingFocus: "The ghosts are there to animate the gaps, not to erase them. The kick displacement still does the real structural work.",
                swingAmount: 0.20,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 11], accents: [0, 11], note: "The missing floor kicks are the point."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Keeps 2 and 4 in your body."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(), note: "Shuffled glue through the gaps."),
                    lane("texture", .texture, "Shaker ghosts", .shaker, [3, 7, 15], accents: [7, 15], role: .commentary, timing: shuffledSixteenth(0.8), note: "Tiny nudges that make the gaps spring.")
                ]
            ),
            RhythmVariant(
                id: "two-step-airy",
                name: "Airy Shuffle",
                summary: "A more spacious top line that makes the kick displacement and stop-start body pull easier to hear.",
                hearingFocus: "The highs keep time, but the identity still comes from how the kicks dodge the floor-kick expectation.",
                swingAmount: 0.24,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 11], accents: [0, 11], note: "The missing floor kicks are the point."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Keeps 2 and 4 in your body."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Shuffled glue through the gaps."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], timing: shuffledSixteenth(0.75), note: "Late lift before the reset."),
                    lane("texture", .texture, "Ghosts", .shaker, [3, 5, 13], accents: [5, 13], role: .commentary, timing: shuffledSixteenth(0.85), note: "Tiny nudges that make the gaps spring.")
                ]
            )
        ],
        teachingOverlays: [
            "Show the house-grid quarter-note expectation behind the actual kick placements",
            "Highlight missing floor-kick positions as negative space",
            "Mark swung high-lane steps differently from straight grid steps",
            "Keep the snare frame visible so the broken kicks do not feel random"
        ],
        notes: [
            "The Wire's 1999 two-step essay is useful here: one of the clearest descriptions is that 2-step works by removing kicks from the four-floor garage pulse and turning the resulting gaps into feel.",
            "This is a canonical 2-step learning groove rather than a transcription of one record."
        ]
    )

    private static let houseCore = RhythmDefinition(
        id: "house-core",
        name: "House Core",
        alternateName: "Four-floor house",
        tradition: "Global club lineage",
        family: "House",
        region: .globalElectronic,
        tier: .solid,
        summary: "The stable four-floor reference case in this library: quarter-note kick, clap on 2 and 4, offbeat open hats, and optional quieter feel hats that create lift without threatening the floor.",
        hearingCue: "Lock to the floor kick first, then notice how the offbeat hat answers every kick rather than floating freely.",
        feelKeywords: ["Stable floor", "Offbeat answer", "Even pulse", "Late feel hats"],
        cycle: fourFourSixteenth,
        defaultTempo: 124,
        tempoRange: 118...128,
        variants: [
            RhythmVariant(
                id: "house-core-foundation",
                name: "Basic",
                summary: "The stripped house argument: four-floor kick plus offbeat open hat. If that pair does not roll, the rest is garnish.",
                hearingFocus: "Lock to the four-floor first, then hear the open hat as the answer on every upbeat.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "low",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Stable floor."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Offbeat answer that makes the four-floor roll forward.")
                ]
            ),
            RhythmVariant(
                id: "house-core-frame",
                name: "Clap Frame",
                summary: "Adds the common 2-and-4 clap and a simple upper skeleton without disturbing the basic floor-and-upbeat conversation.",
                hearingFocus: "The clap clarifies the body pulse, but the open hat is still the line that answers every kick.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Stable floor."),
                    lane("hand", .backbeatHand, "Clap", .clap, [4, 12], accents: [4, 12], note: "2-and-4 frame."),
                    lane("closed", .closedHigh, "Closed hat", .closedHat, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Quarter-note top skeleton."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Offbeat answer that makes the four-floor roll forward.")
                ]
            ),
            RhythmVariant(
                id: "house-core-feel-hats",
                name: "Feel Hats",
                summary: "Adds the quieter in-between hats that make a rigid house grid feel skippy rather than blocky.",
                hearingFocus: "The kick is still mathematically obvious. The groove comes from how the quieter hats lean around the open-hat answer.",
                swingAmount: 0.06,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Stable floor."),
                    lane("hand", .backbeatHand, "Clap", .clap, [4, 12], accents: [4, 12], note: "2-and-4 frame."),
                    lane("closed", .closedHigh, "Closed hat", .closedHat, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Quarter-note top skeleton."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Offbeat answer that makes the four-floor roll forward."),
                    lane("texture", .texture, "Feel hats", .closedHat, [7, 9, 13, 15], accents: [7, 15], role: .commentary, timing: shuffledSixteenth(), note: "Quiet bend in the grid.")
                ]
            ),
            RhythmVariant(
                id: "house-core-jack",
                name: "Jacking Topline",
                summary: "Brings back a steadier upper layer while keeping the basic house conversation between kick, clap, and offbeat open hat intact.",
                hearingFocus: "Even with more top-end motion, the identity still comes from the offbeat open hat answering the four-floor kick.",
                swingAmount: 0.04,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "open",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Stable floor."),
                    lane("hand", .backbeatHand, "Clap", .clap, [4, 12], accents: [4, 12], note: "2-and-4 frame."),
                    lane("closed", .closedHigh, "Closed hat", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(0.75), note: "Steadier topline that makes it jack."),
                    lane("open", .openHigh, "Open hat", .openHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Offbeat answer that makes the four-floor roll forward."),
                    lane("texture", .texture, "Shaker", .shaker, [7, 15], accents: [7, 15], role: .commentary, timing: shuffledSixteenth(0.8), note: "Tail-end chatter for lift.")
                ]
            )
        ],
        teachingOverlays: [
            "Highlight all quarter-note kicks as the non-negotiable floor",
            "Show the offbeat open hat as the answer layer between kicks",
            "Dim the quieter feel hats so they read as seasoning, not the main argument",
            "Use this as the stable contrast case for 2-step and as the softer contrast case for techno"
        ],
        notes: [
            "MusicRadar's classic-house walkthrough was useful for the core grammar here: kick on every quarter note, open hats on the offbeats, clap on 2 and 4, with quieter feel hats placed slightly behind the beat.",
            "This entry is intentionally simpler than a full production breakdown. The goal is to teach what later garage and techno variants are changing."
        ]
    )

    private static let fourByFourGarage = RhythmDefinition(
        id: "four-by-four-garage",
        name: "4x4 Garage",
        alternateName: "Pre-2-step UK garage",
        tradition: "UK",
        family: "UK Garage",
        region: .uk,
        tier: .solid,
        summary: "The earlier garage strand that keeps the four-floor kick intact but bends the upper layers with heavy swing, ghost details, and turnaround snare figures.",
        hearingCue: "The floor kick still tells you where home is. The swing and flex live above it.",
        feelKeywords: ["4x4 base", "Heavy swing", "Glossy", "Garage flex"],
        cycle: fourFourSixteenth,
        defaultTempo: 132,
        tempoRange: 128...135,
        variants: [
            RhythmVariant(
                id: "garage-4x4-core",
                name: "Basic",
                summary: "The minimal 4x4 garage skeleton: floor kick, snare frame, shuffled hats, and the classic late open-hat lift.",
                hearingFocus: "Hear the floor kick as home, then notice that the garage identity comes from the swung high layers rather than from removing the floor.",
                swingAmount: 0.18,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Four-floor home base."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Backbeat frame under the swing."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(), note: "Swung hat motor."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], timing: shuffledSixteenth(0.8), note: "Late lift into the reset.")
                ]
            ),
            RhythmVariant(
                id: "garage-4x4-ghosts",
                name: "Ghost Notes",
                summary: "Adds the small ghost events that make the swung skeleton feel springy rather than rigid.",
                hearingFocus: "The ghosts should animate the hats, not compete with the kick or snare frame.",
                swingAmount: 0.18,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Four-floor home base."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Backbeat frame under the swing."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(), note: "Swung hat motor."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], timing: shuffledSixteenth(0.8), note: "Late lift into the reset."),
                    lane("texture", .texture, "Ghosts", .shaker, [3, 11], accents: [3, 11], role: .commentary, timing: shuffledSixteenth(0.85), note: "Glossy chatter around the swing.")
                ]
            ),
            RhythmVariant(
                id: "garage-4x4-ghosted",
                name: "Ghost Kick",
                summary: "Adds a low ghost kick and a denser top line so the groove springs toward the turnaround without abandoning the floor.",
                hearingFocus: "The extra kick is not a new foundation. It is a nudge toward the loop reset while the swung hats keep the garage sheen intact.",
                swingAmount: 0.22,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12, 15], accents: [0, 4, 8, 12], note: "Four-floor home base."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Backbeat frame under the swing."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(), note: "Swung hat motor."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], timing: shuffledSixteenth(0.85), note: "Late lift into the reset."),
                    lane("texture", .texture, "Ghosts", .shaker, [3, 9, 11], accents: [3, 11], role: .commentary, timing: shuffledSixteenth(), note: "Glossy chatter around the swing.")
                ]
            ),
            RhythmVariant(
                id: "garage-4x4-turnaround",
                name: "Turnaround Jack",
                summary: "Introduces the crunchy turnaround snare figure that gives old-school garage its jacking tail-end push.",
                hearingFocus: "The extra snare is a turnaround gesture, not a new backbeat. The floor kick remains the thing 2-step will later remove.",
                swingAmount: 0.2,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 4, 8, 12], accents: [0, 4, 8, 12], note: "Four-floor home base."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12, 14], accents: [4, 12, 14], note: "Backbeat frame under the swing."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 5, 6, 10, 13, 14], accents: [2, 6, 10, 14], timing: shuffledSixteenth(), note: "Swung hat motor."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], timing: shuffledSixteenth(0.85), note: "Late lift into the reset."),
                    lane("texture", .texture, "Ghosts", .shaker, [3, 11], accents: [3, 11], role: .commentary, timing: shuffledSixteenth(0.85), note: "Glossy chatter around the swing.")
                ]
            )
        ],
        teachingOverlays: [
            "Keep the four-floor kick visible so the contrast with 2-step is immediate",
            "Highlight the swung hats just before the offbeat open hat",
            "Mark turnaround figures separately from the stable snare frame",
            "Show that garage swing can be heavy without breaking the floor"
        ],
        notes: [
            "MusicRadar's UK garage overview was useful for the family history: early garage retains the 4x4 kick, while later 2-step displaces or removes it.",
            "Attack Magazine's retro and Jersey-garage breakdowns were useful for the feel details here: heavy swing in the hats, offbeat open hats, ghosting, and turnaround jack figures.",
            "This entry exists mainly as a contrast case for 2-step: same family, different kick logic."
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
        summary: "A more continuous Brazilian pulse than bossa nova, with surdo propulsion underneath and a steadier top layer often traced through pandeiro- or tamborim-like motion.",
        hearingCue: "Do not hear this as bossa sped up. Hear the constant surface motion and the surdo push underneath it.",
        feelKeywords: ["Continuous", "Forward", "Battery pulse", "Surface shimmer"],
        cycle: fourFourSixteenth,
        defaultTempo: 104,
        tempoRange: 96...120,
        variants: [
            RhythmVariant(
                id: "samba-pandeiro",
                name: "Basic",
                summary: "Just the moving surdo and the constant pandeiro stream, which is enough to make samba feel like forward motion rather than backbeat music.",
                hearingFocus: "Let the pandeiro establish the stream of motion first, then notice how the surdo pushes through it.",
                swingAmount: 0.03,
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 3, 8, 11], accents: [0, 8], note: "Moving low push under the stream."),
                    lane("texture", .texture, "Pandeiro", .pandeiro, Array(stride(from: 0, to: 16, by: 2)), accents: [0, 4, 8, 12], note: "Constant stream that keeps samba moving.")
                ]
            ),
            RhythmVariant(
                id: "samba-tamborim",
                name: "Tamborim Lift",
                summary: "Adds the bright upper response that gives the basic surdo-and-pandeiro flow more bite and lift.",
                hearingFocus: "The tamborim should sit on top of the stream, not replace it. The pandeiro and surdo still define the motion.",
                swingAmount: 0.03,
                accentGuideHostLaneID: "aux1",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 3, 8, 11], accents: [0, 8], note: "Moving low push under the stream."),
                    lane("texture", .texture, "Pandeiro", .pandeiro, Array(stride(from: 0, to: 16, by: 2)), accents: [0, 4, 8, 12], note: "Constant stream that keeps samba moving."),
                    lane("aux1", .aux1, "Tamborim", .tamborim, [3, 7, 11, 15], accents: [7, 15], role: .lift, note: "Bright lift on top of the stream.")
                ]
            ),
            RhythmVariant(
                id: "samba-battery",
                name: "Battery Layers",
                summary: "Adds caixa- and agogo-like functions so the groove reads more like interlocking battery roles than a drum-set reduction.",
                hearingFocus: "The identity comes from interlocking roles, not a single backbeat. Hear the top stream, then the surdo, then the lighter answering layers.",
                swingAmount: 0.03,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "timeline",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Surdo", .surdo, [0, 3, 8, 11], accents: [0, 8], note: "Moving low push under the stream."),
                    lane("hand", .backbeatHand, "Caixa", .caixa, [2, 6, 10, 14], accents: [2, 10], role: .counterline, note: "Answering crack inside the battery."),
                    lane("timeline", .timeline, "Agogo", .agogo, [0, 4, 8, 12], accents: [0, 8], note: "Bright timeline for the battery."),
                    lane("texture", .texture, "Pandeiro", .pandeiro, Array(stride(from: 0, to: 16, by: 2)), accents: [0, 4, 8, 12], note: "Constant stream that keeps samba moving.")
                ]
            ),
            RhythmVariant(
                id: "samba-kit",
                name: "Kit Translation",
                summary: "A drum-set-shaped reduction that keeps samba moving by preserving the constant upper layer and low-drum propulsion.",
                hearingFocus: "If this starts to sound like Latin pop, return to the constant upper-line flow and the more mobile low drum.",
                swingAmount: 0.03,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick / Surdo", .kick, [0, 3, 8, 11], accents: [0, 8], note: "Surdo motion on a kit kick."),
                    lane("hand", .backbeatHand, "Cross-stick", .crossStick, [4, 12], accents: [4, 12], role: .counterline, note: "Light frame so the motion stays fluid."),
                    lane("closed", .closedHigh, "Closed cymbal", .closedHat, Array(stride(from: 0, to: 16, by: 2)), accents: [2, 6, 10, 14], note: "Steady upper stream for the kit version."),
                    lane("texture", .texture, "Shaker", .shaker, [3, 7, 11, 15], accents: [7, 15], role: .commentary, note: "Extra lift at the edges.")
                ]
            )
        ],
        teachingOverlays: [
            "Keep the pulse visible while the surdo moves around it",
            "Highlight the constant top subdivision as continuity rather than decoration",
            "Separate interlocking battery roles from drum-set translation",
            "Use this to contrast bossa's long phrase with samba's more continuous churn"
        ],
        notes: [
            "Carnegie Hall's samba materials were useful here for the instrument roles and teaching emphasis on interlocking surdo, tamborim, agogo, and pandeiro layers.",
            "A Carnegie Hall pandeiro lesson also emphasized that one basic samba rhythm is a constant stream of eighth notes, which is why the continuity layer is so exposed here.",
            "This solid-tier entry exists as a bridge outward from bossa nova, not as a definitive chart of one samba school arrangement."
        ]
    )

    private static let sonClave = RhythmDefinition(
        id: "son-clave",
        name: "Son Clave",
        alternateName: "3-2 and 2-3 orientations",
        tradition: "Afro-Cuban",
        family: "Clave",
        region: .afroCuban,
        tier: .solid,
        summary: "A timeline entry where the clave line is structural reference, not decoration, and where the distinction between 3-2 and 2-3 matters because phrase order matters.",
        hearingCue: "Hear the clave as orientation. The other lanes are there to reveal the timeline, not to compete with it.",
        feelKeywords: ["Timeline", "Reference pattern", "3-side / 2-side", "Orientation"],
        cycle: twoBarFourFourSixteenth,
        defaultTempo: 98,
        tempoRange: 90...110,
        variants: [
            RhythmVariant(
                id: "son-3-2",
                name: "Basic",
                summary: "Just the 3-2 clave line, with nothing else to distract from the phrase order.",
                hearingFocus: "Do not just count five hits. Hear the three-side first, then feel the two-side answer.",
                swingAmount: 0.04,
                backbeatGuideHostLaneID: "timeline",
                accentGuideHostLaneID: "timeline",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("timeline", .timeline, "Clave", .clave, [0, 6, 12, 18, 24], accents: [0, 6, 12, 18, 24], note: "Orientation line. Everything else hangs off it.")
                ]
            ),
            RhythmVariant(
                id: "son-3-2-support",
                name: "3-2 Support",
                summary: "Adds the common support layers that make the clave easier to hear as structure instead of as five isolated hits.",
                hearingFocus: "The support should reveal the clave, not compete with it. Listen for the orientation line first.",
                swingAmount: 0.04,
                backbeatGuideHostLaneID: "timeline",
                accentGuideHostLaneID: "timeline",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("timeline", .timeline, "Clave", .clave, [0, 6, 12, 18, 24], accents: [0, 6, 12, 18, 24], note: "Orientation line. Everything else hangs off it."),
                    lane("low", .lowDrum, "Conga support", .congaLow, [0, 10, 16, 26], accents: [10, 26], note: "Supports the clave phrase underneath."),
                    lane("texture", .texture, "Shaker", .shaker, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [2, 6, 10, 14, 18, 22, 26, 30], note: "Keeps the phrase audible as motion.")
                ]
            ),
            RhythmVariant(
                id: "son-2-3",
                name: "2-3 Support",
                summary: "The same timeline family, but reoriented so the two-side arrives first and the three-side answers in bar two.",
                hearingFocus: "This is not the same groove starting in a different place. The phrase order changes the orientation of everything around it.",
                swingAmount: 0.04,
                backbeatGuideHostLaneID: "timeline",
                accentGuideHostLaneID: "timeline",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12, 16, 20, 24, 28], accents: [0, 4, 8, 12, 16, 20, 24, 28]),
                    lane("timeline", .timeline, "Clave", .clave, [4, 8, 16, 22, 28], accents: [4, 8, 16, 22, 28], note: "Orientation line. Everything else hangs off it."),
                    lane("low", .lowDrum, "Conga support", .congaLow, [4, 14, 20, 30], accents: [14, 30], note: "Supports the clave phrase underneath."),
                    lane("texture", .texture, "Shaker", .shaker, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30], accents: [2, 6, 10, 14, 18, 22, 26, 30], note: "Keeps the phrase audible as motion.")
                ]
            )
        ],
        teachingOverlays: [
            "Display the timeline lane in a dedicated color",
            "Shade the three-side and two-side as separate phrase regions",
            "Keep the bar divider obvious so orientation is visible, not implied",
            "Use this to show that clave is a structural reference rather than a garnish"
        ],
        notes: [
            "SFJAZZ's clave breakdown was useful here because it frames clave as the fundamental rhythmic basis of much Afro-Cuban and Afro-Caribbean music and stresses listening orientation rather than memorizing dots.",
            "Carnegie Hall's danzon material was also useful for phrasing clave as an African-based rhythm that combines a syncopated phrase with a non-syncopated phrase.",
            "This is still a teaching reduction. The goal is to make 3-2 versus 2-3 audible and visible in the app."
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
                name: "Basic",
                summary: "Just the kick-and-snare sentence. If this does not nod on its own, the hats will not save it.",
                hearingFocus: "Hear the kick setting up the snare instead of acting like a constant floor.",
                swingAmount: 0.1,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 7, 10], accents: [0, 10], note: "Sets up the snare instead of flooring every beat."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Center of the pocket.")
                ]
            ),
            RhythmVariant(
                id: "boom-bap-hats",
                name: "Hat Pocket",
                summary: "Adds the laid-back hat line that turns the kick-and-snare sentence into a head-nod pocket.",
                hearingFocus: "The hats should glue the loop together, not rush it forward.",
                swingAmount: 0.1,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 7, 10], accents: [0, 10], note: "Sets up the snare instead of flooring every beat."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Center of the pocket."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Laid-back glue.")
                ]
            ),
            RhythmVariant(
                id: "boom-bap-lift",
                name: "Phrase Lift",
                summary: "Adds the little phrase-end lift you often hear in sampled-break and boom bap loops.",
                hearingFocus: "That extra air at the end of the bar should feel like a lift into the reset, not a dance-pop open hat.",
                swingAmount: 0.1,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 7, 10], accents: [0, 10], note: "Sets up the snare instead of flooring every beat."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Center of the pocket."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Laid-back glue."),
                    lane("open", .openHigh, "Open hat", .openHat, [15], accents: [15], note: "Little lift into the barline.")
                ]
            ),
            RhythmVariant(
                id: "boom-bap-ghosts",
                name: "Ghost Notes",
                summary: "Adds light ghost commentary around the backbeat so the loop feels more played than programmed.",
                hearingFocus: "The ghosts should support the main snare, not steal its weight.",
                swingAmount: 0.12,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "hand",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 7, 10], accents: [0, 10], note: "Sets up the snare instead of flooring every beat."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 12], accents: [4, 12], note: "Center of the pocket."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], timing: laidBackOffbeat(), note: "Laid-back glue."),
                    lane("open", .openHigh, "Open hat", .openHat, [15], accents: [15], note: "Little lift into the barline."),
                    lane("aux1", .aux1, "Ghost snare", .snare, [3, 11], accents: [11], role: .commentary, note: "Quiet comments around the backbeat.")
                ]
            )
        ],
        teachingOverlays: [
            "Start with kick and snare only, then add the hat pocket",
            "Show the snare as the center of the groove, not a marker",
            "Keep the laid-back hats visually behind the backbeat",
            "Mark phrase-end lift and ghost notes as optional additions"
        ],
        notes: [
            "This entry treats boom bap as a pocket family built from kick-snare argument, laid-back hats, and optional break-derived lift rather than from trap-style subdivision density."
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
        summary: "A ride-led swing pattern where the cymbal line carries the time, the hi-hat foot marks 2 and 4, and the bass drum remains supportive rather than dominant.",
        hearingCue: "Hear the ride cymbal as the real clock. The rest of the kit comments around it.",
        feelKeywords: ["Ride-led", "Swing", "Lift", "Hi-hat on 2 and 4"],
        cycle: twelveEight,
        defaultTempo: 148,
        tempoRange: 132...176,
        variants: [
            RhythmVariant(
                id: "jazz-ride-core",
                name: "Basic",
                summary: "Just the ride cymbal and hi-hat foot, which is enough to state the swing pulse clearly.",
                hearingFocus: "The skipped middle subdivision is where the bounce lives. If you flatten that, you flatten the feel.",
                swingAmount: 0.2,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 3, 6, 9], accents: [0, 3, 6, 9]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 2, 3, 5, 6, 8, 9, 11], accents: [0, 3, 6, 9], note: "The real clock."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [3, 9], accents: [3, 9], note: "Puts 2 and 4 in the body.")
                ]
            ),
            RhythmVariant(
                id: "jazz-ride-light-bass",
                name: "Feathered Bass",
                summary: "Adds soft quarter-note bass drum support under the ride and hi-hat relationship.",
                hearingFocus: "The bass drum should support the ride, not become the thing you follow.",
                swingAmount: 0.2,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 3, 6, 9], accents: [0, 3, 6, 9]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 2, 3, 5, 6, 8, 9, 11], accents: [0, 3, 6, 9], note: "The real clock."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [3, 9], accents: [3, 9], note: "Puts 2 and 4 in the body."),
                    lane("low", .lowDrum, "Bass drum", .kick, [0, 3, 6, 9], accents: [0, 3, 6, 9], note: "Soft feathering under the ride.")
                ]
            ),
            RhythmVariant(
                id: "jazz-ride-comping",
                name: "Ride With Comping",
                summary: "Adds light snare comping so the ride remains the clock while the rest of the kit becomes conversational.",
                hearingFocus: "The extra snare hits are comments, not the pulse. If they become the clock, the ride has stopped leading.",
                swingAmount: 0.2,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 3, 6, 9], accents: [0, 3, 6, 9]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 2, 3, 5, 6, 8, 9, 11], accents: [0, 3, 6, 9], note: "The real clock."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [3, 9], accents: [3, 9], note: "Puts 2 and 4 in the body."),
                    lane("low", .lowDrum, "Feathered kick", .kick, [0, 3, 6, 9], accents: [0, 3, 6, 9], note: "Soft feathering under the ride."),
                    lane("aux1", .aux1, "Snare comping", .snare, [5, 11], accents: [11], note: "Comments around the ride line.")
                ]
            )
        ],
        teachingOverlays: [
            "Render triplet subdivision labels clearly",
            "Highlight the skipped middle triplet that creates the ride bounce",
            "Keep the hi-hat foot on 2 and 4 visible as a separate anchor",
            "Show that comping comments on the ride pattern rather than replacing it"
        ],
        notes: [
            "Percussive Arts Society material was useful for grounding the ride pattern as dotted-eighth plus sixteenth motion rather than a straight-eighth simplification.",
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
        tier: .solid,
        summary: "A clipped Caribbean backbone whose repeating kick-snare statement became foundational to reggaeton and later dembow-derived styles.",
        hearingCue: "Hear the bar as a repeating statement, not a generic kick-snare-hat loop. The pattern keeps saying the same sentence.",
        feelKeywords: ["Direct", "Looping", "Dancehall-derived", "Backbone"],
        cycle: fourFourSixteenth,
        defaultTempo: 96,
        tempoRange: 88...104,
        variants: [
            RhythmVariant(
                id: "dembow-core",
                name: "Basic",
                summary: "Just the kick-and-snare sentence that makes dembow snap back to the top of the bar.",
                hearingFocus: "Do not hear this as four unrelated hits. Hear a single recursive statement that keeps snapping back to the top.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 8, 11], accents: [0, 8], note: "This kick sentence is the backbone."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 10, 12], accents: [4, 12], note: "Completes the dembow sentence.")
                ]
            ),
            RhythmVariant(
                id: "dembow-hats",
                name: "Hat Skeleton",
                summary: "Adds the bright offbeat hat skeleton without changing the basic kick-and-snare sentence.",
                hearingFocus: "The highs should sharpen the loop, not distract from the backbone.",
                swingAmount: 0,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 8, 11], accents: [0, 8], note: "This kick sentence is the backbone."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 10, 12], accents: [4, 12], note: "Completes the dembow sentence."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Bright top skeleton.")
                ]
            ),
            RhythmVariant(
                id: "dembow-air",
                name: "Reggaeton Air",
                summary: "Adds upper-layer motion without changing the core kick-snare sentence that makes the groove legible.",
                hearingFocus: "The extra highs should feel like air above the loop. The identity still lives in the kick and snare placements.",
                swingAmount: 0.02,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "low",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8, 12], accents: [0, 4, 8, 12]),
                    lane("low", .lowDrum, "Kick", .kick, [0, 6, 8, 11], accents: [0, 8], note: "This kick sentence is the backbone."),
                    lane("hand", .backbeatHand, "Snare", .snare, [4, 10, 12], accents: [4, 12], note: "Completes the dembow sentence."),
                    lane("closed", .closedHigh, "Hat", .closedHat, [2, 6, 10, 14], accents: [2, 6, 10, 14], note: "Bright top skeleton."),
                    lane("open", .openHigh, "Open hat", .openHat, [7, 15], accents: [7, 15], note: "Air into the reset."),
                    lane("texture", .texture, "Shaker", .shaker, [0, 2, 4, 6, 8, 10, 12, 14], accents: [2, 6, 10, 14], note: "Extra motion above the backbone.")
                ]
            )
        ],
        teachingOverlays: [
            "Show the repeating kick-snare sentence as one loop-shaped idea",
            "Keep the barline clear so the reset remains audible",
            "Use this as a Caribbean contrast case against cumbia's layered continuity",
            "Let the user mute highs and hear how much identity remains in the backbone alone"
        ],
        notes: [
            "Wayne Marshall's dembow loop history was useful here: it treats the dembow as a foundational loop with a lineage through Jamaican and Panamanian collaboration rather than as an isolated reggaeton invention.",
            "The exact historical recording lineage is more complex than the shorthand 'Shabba Ranks invented the beat,' but the app still uses the familiar dembow name because that is how most musicians encounter the pattern."
        ]
    )

    private static let jazzWaltz = RhythmDefinition(
        id: "jazz-waltz",
        name: "Jazz Waltz",
        alternateName: nil,
        tradition: "Jazz",
        family: "Waltz",
        region: .jazzTradition,
        tier: .solid,
        summary: "A three-beat swing feel where circular ride motion carries the time and the rest of the kit supports that orbit rather than imposing a backbeat.",
        hearingCue: "Hear three big beats with a continuing ride phrase, not 4/4 swing with one beat chopped off.",
        feelKeywords: ["Triple meter", "Ride-led", "Circular", "Lift"],
        cycle: threeFourSwing,
        defaultTempo: 150,
        tempoRange: 132...168,
        variants: [
            RhythmVariant(
                id: "jazz-waltz-core",
                name: "Basic",
                summary: "Just the ride pattern and hi-hat-foot anchors, enough to make the three-beat swing feel audible.",
                hearingFocus: "Let the repeating groups of three settle before listening for anything else.",
                swingAmount: 0.12,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8], accents: [0, 4, 8]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 3, 4, 7, 8, 11], accents: [0, 4, 8], note: "Circular ride line across three."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [4, 8], accents: [4, 8], note: "Body anchor on beats 2 and 3.")
                ]
            ),
            RhythmVariant(
                id: "jazz-waltz-feather",
                name: "Feathered Bass",
                summary: "Adds soft bass-drum support under the ride and hi-hat-foot pattern.",
                hearingFocus: "The bass drum should support the ride orbit, not drag the groove toward a march.",
                swingAmount: 0.12,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8], accents: [0, 4, 8]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 3, 4, 7, 8, 11], accents: [0, 4, 8], note: "Circular ride line across three."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [4, 8], accents: [4, 8], note: "Body anchor on beats 2 and 3."),
                    lane("low", .lowDrum, "Bass drum", .kick, [0, 4, 8], accents: [0, 4, 8], note: "Soft feathering under all three beats.")
                ]
            ),
            RhythmVariant(
                id: "jazz-waltz-comping",
                name: "Snare Comments",
                summary: "Adds sparse snare comments around the circular ride pattern.",
                hearingFocus: "The snare should sound like comments around the ride, not a new clock.",
                swingAmount: 0.12,
                backbeatGuideHostLaneID: "hand",
                accentGuideHostLaneID: "closed",
                lanes: [
                    lane("pulse", .pulse, "Click", .click, [0, 4, 8], accents: [0, 4, 8]),
                    lane("closed", .closedHigh, "Ride cymbal", .ride, [0, 3, 4, 7, 8, 11], accents: [0, 4, 8], note: "Circular ride line across three."),
                    lane("hand", .backbeatHand, "Hi-hat foot", .hiHatFoot, [4, 8], accents: [4, 8], note: "Body anchor on beats 2 and 3."),
                    lane("low", .lowDrum, "Bass drum", .kick, [0, 4, 8], accents: [0, 4, 8], note: "Soft feathering under all three beats."),
                    lane("aux1", .aux1, "Snare comping", .snare, [3, 11], accents: [11], role: .commentary, note: "Short comments between ride figures.")
                ]
            )
        ],
        teachingOverlays: [
            "Keep three big beats visible under the subdivided ride pattern",
            "Highlight the hi-hat foot as the body anchor on beats 2 and 3",
            "Show feathered bass drum as support rather than statement",
            "Mark snare comping as commentary around the ride"
        ],
        notes: [
            "Jim Catalano's jazz ensemble drum set presentation was useful here because it treats ride cymbal, hi-hat foot, feathering, and jazz waltz as connected timekeeping problems rather than isolated patterns."
        ]
    )

    private static func lane(
        _ id: String,
        _ slot: LaneSlot,
        _ instrument: String,
        _ voice: InstrumentVoice,
        _ hits: [Int],
        accents: Set<Int> = [],
        role: SharedLineRole? = nil,
        note: String? = nil,
        timing: LaneTiming? = nil
    ) -> RhythmLane {
        RhythmLane(
            id: id,
            slot: slot,
            role: role ?? slot.defaultSharedRole,
            instrument: instrument,
            note: note,
            voice: voice,
            timing: timing,
            events: hits.sorted().map { step in
                StepEvent(
                    step: step,
                    intensity: accents.contains(step) ? 1.0 : 0.72,
                    isAccent: accents.contains(step)
                )
            }
        )
    }

    private static func laidBackOffbeat(_ amountMultiplier: Double = 1.0) -> LaneTiming {
        LaneTiming(profile: .laidBackOffbeat, amountMultiplier: amountMultiplier)
    }

    private static func shuffledSixteenth(_ amountMultiplier: Double = 1.0) -> LaneTiming {
        LaneTiming(profile: .shuffledSixteenth, amountMultiplier: amountMultiplier)
    }
}
