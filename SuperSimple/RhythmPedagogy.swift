import Foundation

extension RhythmDefinition {
    var identityMarkers: [String] {
        switch id {
        case "cumbia":
            [
                "Three fixed layers plus improvised alegre",
                "Llamador answers against a stepped 1 / 3 orientation",
                "Maraca continuity keeps the dance moving",
                "Tambora weight gives the groove its grounded pull"
            ]
        case "bossa-nova":
            [
                "Two-bar phrase, not one-bar looping",
                "Low drum implies surdo logic more than rock kick logic",
                "Side-stick draws the syncopation contour",
                "Straight subdivision with soft forward lean"
            ]
        case "classic-techno":
            [
                "Quarter-note kick certainty",
                "Clap stabilizes 2 and 4 without stealing focus",
                "Offbeat hats create the air around the floor",
                "Tiny hat changes are enough to change intensity"
            ]
        case "two-step":
            [
                "Snare frame still orients 2 and 4",
                "Floor kicks are removed or displaced",
                "Busy highs keep time while kicks hesitate",
                "Negative space is part of the groove"
            ]
        case "samba":
            [
                "Continuous top texture",
                "Propulsive low-drum motion"
            ]
        case "house-core":
            [
                "Continuous four-on-the-floor",
                "Offbeat openness without broken kick logic"
            ]
        case "four-by-four-garage":
            [
                "4x4 floor kick remains intact",
                "Shuffle lives in hats and ghosts"
            ]
        case "son-clave":
            [
                "Timeline first",
                "Everything else orients around the clave"
            ]
        case "dembow":
            [
                "Kick-snare statement loop",
                "Direct, heavily legible phrase"
            ]
        default:
            feelKeywords
        }
    }

    var mishearRisk: String? {
        switch id {
        case "cumbia":
            "If the hand part flips onto 1 and 3 without feeling the stepped orientation underneath, the groove loses its cumbia pull."
        case "bossa-nova":
            "If you hear it bar-by-bar or force a pop backbeat onto it, the long phrase collapses."
        case "classic-techno":
            "If every lane becomes equally busy, the groove stops teaching the efficiency that makes classic techno work."
        case "two-step":
            "If the kicks fill back into all four beats, the groove turns into 4x4 garage or house."
        default:
            nil
        }
    }

    var relatedRhythmIDs: [String] {
        switch id {
        case "cumbia":
            ["dembow", "son-clave"]
        case "bossa-nova":
            ["samba", "jazz-ride"]
        case "classic-techno":
            ["house-core", "four-by-four-garage"]
        case "two-step":
            ["four-by-four-garage", "house-core"]
        case "house-core":
            ["classic-techno", "two-step"]
        case "four-by-four-garage":
            ["two-step", "house-core"]
        default:
            []
        }
    }
}
