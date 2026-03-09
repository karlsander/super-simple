import Foundation

actor KinoAPIClient {
    static let shared = KinoAPIClient()

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
    }

    // MARK: - Movies List

    func fetchMovies(
        location: Location = .berlin,
        sortBy: String = "popularity",
        offset: Int = 0
    ) async throws -> MovieListResponse {
        var components = URLComponents(string: "\(baseURL)/api/cinemas/")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "radius", value: String(location.radius)),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        return try await request(url: components.url!)
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
