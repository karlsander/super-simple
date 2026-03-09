import Foundation

actor KinoAPIClient {
    static let shared = KinoAPIClient()

    init() {
        loadDiskCache()
    }

    private let baseURL = "https://kinoapi.apps.stroeermb.de"
    private let accessToken = "0A51269E-2C81-47BD-B8E5-5EA1232F1804"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Accept": "*/*"]
        return URLSession(configuration: config)
    }()

    struct Location {
        let latitude: Double
        let longitude: Double
        let radius: Int

        // Default: Berlin Prenzlauer Berg
        static let berlin = Location(latitude: 52.5374648658, longitude: 13.4222464119, radius: 10)

        /// Round to ~1-2 km precision (1 decimal place ≈ 11 km, 2 ≈ 1.1 km)
        var cacheKey: String {
            let lat = (latitude * 100).rounded() / 100
            let lon = (longitude * 100).rounded() / 100
            return "\(lat),\(lon),\(radius)"
        }
    }

    // MARK: - List Cache

    private struct CachedList: Codable {
        let response: MovieListResponse
        let timestamp: Date
    }

    private var listCache: [String: CachedList] = [:]
    private let cacheExpiry: TimeInterval = 5 * 60 * 60 // 5 hours

    private static var diskCacheDir: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("MovieListCache", isDirectory: true)
    }

    private func listCacheKey(location: Location, sortBy: String, offset: Int) -> String {
        "\(location.cacheKey)|\(sortBy)|\(offset)"
    }

    private func diskPath(for key: String) -> URL {
        let safe = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return Self.diskCacheDir.appendingPathComponent(safe + ".json")
    }

    private func loadDiskCache() {
        let dir = Self.diskCacheDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let entry = try? decoder.decode(CachedList.self, from: data) else {
                try? FileManager.default.removeItem(at: file)
                continue
            }
            if Date().timeIntervalSince(entry.timestamp) < cacheExpiry {
                let key = file.deletingPathExtension().lastPathComponent
                    .removingPercentEncoding ?? file.deletingPathExtension().lastPathComponent
                listCache[key] = entry
            } else {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func saveToDisk(_ entry: CachedList, key: String) {
        try? FileManager.default.createDirectory(at: Self.diskCacheDir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: diskPath(for: key), options: .atomic)
    }

    // MARK: - Movies List

    func fetchMovies(
        location: Location = .berlin,
        sortBy: String = "popularity",
        offset: Int = 0
    ) async throws -> MovieListResponse {
        let key = listCacheKey(location: location, sortBy: sortBy, offset: offset)

        if let cached = listCache[key],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            return cached.response
        }

        var components = URLComponents(string: "\(baseURL)/api/cinemas/")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "radius", value: String(location.radius)),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        let response: MovieListResponse = try await request(url: components.url!)
        let entry = CachedList(response: response, timestamp: Date())
        listCache[key] = entry
        saveToDisk(entry, key: key)
        return response
    }

    // MARK: - Fetch All Pages

    /// Fetches all movie pages upfront with slightly staggered requests.
    func fetchAllMovies(
        location: Location = .berlin,
        sortBy: String = "popularity"
    ) async throws -> [Movie] {
        var allMovies: [Movie] = []
        var offset = 0

        while true {
            let response = try await fetchMovies(location: location, sortBy: sortBy, offset: offset)
            allMovies.append(contentsOf: response.movies)

            guard let next = response.next,
                  let comps = URLComponents(string: next),
                  let offsetItem = comps.queryItems?.first(where: { $0.name == "offset" }),
                  let nextOffset = offsetItem.value.flatMap(Int.init) else {
                break
            }
            offset = nextOffset
            // Small stagger between requests
            try? await Task.sleep(for: .milliseconds(100))
        }

        return allMovies
    }

    // MARK: - Movie Detail

    func fetchMovieDetail(
        id: Int,
        location: Location = .berlin
    ) async throws -> Movie {
        var components = URLComponents(string: "\(baseURL)/api/movies/\(id)")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "radius", value: String(location.radius)),
        ]

        return try await request(url: components.url!)
    }

    // MARK: - Cinema Detail

    func fetchCinemaDetail(id: Int) async throws -> CinemaDetail {
        let url = URL(string: "\(baseURL)/api/cinema_details/\(id)")!
        return try await request(url: url)
    }

    // MARK: - Trailer

    struct OEmbedResponse: Decodable {
        let object: OEmbedObject?
    }

    struct OEmbedObject: Decodable {
        let playlists: [String]?
    }

    func fetchTrailerURL(oEmbedURL: String) async throws -> URL? {
        guard let url = URL(string: oEmbedURL) else { return nil }
        let (data, _) = try await session.data(for: URLRequest(url: url))
        let response = try JSONDecoder().decode(OEmbedResponse.self, from: data)
        guard let urlString = response.object?.playlists?.first else { return nil }
        return URL(string: urlString)
    }

    // MARK: - Private

    private func request<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(accessToken, forHTTPHeaderField: "accesstoken")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.httpError(statusCode: statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: LocalizedError {
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "Server returned status \(code)"
        }
    }
}
