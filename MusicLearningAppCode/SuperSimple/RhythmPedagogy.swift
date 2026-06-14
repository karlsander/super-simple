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
                "Constant top-line motion, not a sparse backbeat",
                "Surdo push underneath the surface stream",
                "Interlocking battery roles before drum-set translation",
                "More continuous churn than bossa nova"
            ]
        case "house-core":
            [
                "Quarter-note floor kick never drops out",
                "Open hats answer on the offbeats",
                "Clap stabilizes 2 and 4",
                "Quieter feel hats change lift, not identity"
            ]
        case "four-by-four-garage":
            [
                "4x4 floor kick remains intact",
                "Heavy swing lives in hats and ghosts",
                "Turnaround figures add jack without removing the floor",
                "Same family as 2-step, different kick logic"
            ]
        case "son-clave":
            [
                "Timeline first",
                "3-side and 2-side are not interchangeable",
                "Everything else orients around the clave",
                "Phrase order matters as much as hit locations"
            ]
        case "dembow":
            [
                "Kick-snare statement loop",
                "Direct, heavily legible phrase",
                "Loop resets feel like recurring speech",
                "High layers decorate an already complete backbone"
            ]
        case "jazz-ride":
            [
                "Ride cymbal is the primary clock",
                "Hi-hat foot marks 2 and 4",
                "Triplet skip creates bounce",
                "Comping comments around the ride line"
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
        case "house-core":
            "If the offbeat answer disappears, the groove still keeps time, but it stops teaching why house feels open rather than merely square."
        case "four-by-four-garage":
            "If the floor kick drops out, the family resemblance to 2-step becomes misleadingly strong."
        case "samba":
            "If you reduce it to just a backbeat and a kick, it starts reading as generic Latin-pop time instead of samba propulsion."
        case "son-clave":
            "If you hear only five evenly important hits and ignore which side comes first, the orientation disappears."
        case "dembow":
            "If you smooth the kick and snare into a generic reggaeton preset without hearing the recurring statement shape, the groove loses its snap."
        case "jazz-ride":
            "If the ride pattern is flattened into straight eighths, the swing explanation collapses even if the notes are technically still there."
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
            ["classic-techno", "four-by-four-garage"]
        case "four-by-four-garage":
            ["two-step", "house-core"]
        case "samba":
            ["bossa-nova", "jazz-ride"]
        case "son-clave":
            ["cumbia", "dembow"]
        case "dembow":
            ["cumbia", "son-clave"]
        case "jazz-ride":
            ["bossa-nova", "jazz-waltz"]
        default:
            []
        }
    }
}
