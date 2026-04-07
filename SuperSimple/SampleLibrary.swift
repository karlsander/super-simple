import Foundation

struct RhythmSampleReference: Hashable {
    let sourceURL: URL?
    let previewURL: URL?
    let license: String
    let licenseURL: URL?
    let credit: String
    let resourceSubdirectory: String
    let resourceFilename: String

    var resourceName: String {
        URL(fileURLWithPath: resourceFilename).deletingPathExtension().lastPathComponent
    }

    var resourceExtension: String? {
        URL(fileURLWithPath: resourceFilename).pathExtension.nilIfEmpty
    }
}

struct RhythmSamplePack: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let voices: [InstrumentVoice: RhythmSampleReference]
    let isBuiltInSynth: Bool

    static let electronic = RhythmSamplePack(
        id: "electronic",
        name: "Electronic",
        subtitle: "Built-in 808 / 909-style approximations",
        voices: [:],
        isBuiltInSynth: true
    )
}

enum SampleLibrary {
    static func availablePacks() -> [RhythmSamplePack] {
        [RhythmSamplePack.electronic] + loadManifestPacks()
    }

    private static func loadManifestPacks() -> [RhythmSamplePack] {
        guard let manifestURL =
            Bundle.main.url(
                forResource: "sample-library",
                withExtension: "json",
                subdirectory: "Samples"
            ) ??
            Bundle.main.url(
                forResource: "sample-library",
                withExtension: "json"
            ) else {
            return []
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(SampleLibraryManifest.self, from: data)
            return manifest.packs.map(\.samplePack)
        } catch {
            assertionFailure("Failed to load sample-library.json: \(error)")
            return []
        }
    }
}

private struct SampleLibraryManifest: Decodable {
    let packs: [ManifestPack]
}

private struct ManifestPack: Decodable {
    let id: String
    let name: String
    let subtitle: String
    let voices: [String: ManifestVoice]

    var samplePack: RhythmSamplePack {
        let mappedVoices: [InstrumentVoice: RhythmSampleReference] = voices.reduce(into: [:]) { partialResult, entry in
            guard let voice = InstrumentVoice(rawValue: entry.key) else { return }
            partialResult[voice] = entry.value.sampleReference
        }

        return RhythmSamplePack(
            id: id,
            name: name,
            subtitle: subtitle,
            voices: mappedVoices,
            isBuiltInSynth: false
        )
    }
}

private struct ManifestVoice: Decodable {
    let sourceURL: URL?
    let previewURL: URL?
    let license: String
    let licenseURL: URL?
    let credit: String
    let resourceSubdirectory: String
    let resourceFilename: String

    enum CodingKeys: String, CodingKey {
        case sourceURL = "source_url"
        case previewURL = "preview_url"
        case license
        case licenseURL = "license_url"
        case credit
        case resourceSubdirectory = "resource_subdirectory"
        case resourceFilename = "resource_filename"
    }

    var sampleReference: RhythmSampleReference {
        RhythmSampleReference(
            sourceURL: sourceURL,
            previewURL: previewURL,
            license: license,
            licenseURL: licenseURL,
            credit: credit,
            resourceSubdirectory: resourceSubdirectory,
            resourceFilename: resourceFilename
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
