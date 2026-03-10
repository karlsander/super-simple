import Foundation

@Observable @MainActor
final class TMDBCache {
    static let shared = TMDBCache()

    struct CachedInfo: Codable {
        let country: String?
        let languages: [String]?
        let youtubeTrailerKey: String?
    }

    private(set) var entries: [String: CachedInfo] = [:]
    private var inFlight: Set<String> = []

    // Bump this when the cached data shape or fetch logic changes to invalidate old entries
    private static let cacheVersion = 5

    private static var cacheFileURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("TMDBCache_v\(cacheVersion).json")
    }

    private init() {
        if let data = try? Data(contentsOf: Self.cacheFileURL),
           let cached = try? JSONDecoder().decode([String: CachedInfo].self, from: data) {
            entries = cached
        }
    }

    func info(for imdbID: String) -> CachedInfo? {
        entries[imdbID]
    }

    func ensureLoaded(imdbID: String) async {
        guard entries[imdbID] == nil, !inFlight.contains(imdbID) else { return }
        inFlight.insert(imdbID)
        defer { inFlight.remove(imdbID) }

        do {
            let findResult = try await TMDBAPIClient.shared.findByIMDBId(imdbID)
            guard let tmdbMovie = findResult.movieResults.first else {
                entries[imdbID] = CachedInfo(country: nil, languages: nil, youtubeTrailerKey: nil)
                saveToDisk()
                return
            }
            let detail = try await TMDBAPIClient.shared.movieDetailWithVideos(id: tmdbMovie.id)
            let country = detail.productionCountries?.first?.name
                .replacingOccurrences(of: "United States of America", with: "USA")
                .replacingOccurrences(of: "United Kingdom", with: "UK")
            let languages = detail.spokenLanguages?.map(\.englishName)
            // Prefer English YouTube trailer, fall back to any YouTube trailer
            let trailers = detail.videos?.results.filter { $0.site == "YouTube" && $0.type == "Trailer" } ?? []
            let trailer = trailers.first(where: { $0.iso6391 == "en" }) ?? trailers.first
            entries[imdbID] = CachedInfo(country: country, languages: languages, youtubeTrailerKey: trailer?.key)
            saveToDisk()
        } catch {
            // Don't cache errors — will retry next launch
        }
    }

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: Self.cacheFileURL, options: .atomic)
        }
    }
}
