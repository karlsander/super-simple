import Foundation

actor TMDBAPIClient {
    static let shared = TMDBAPIClient()

    private let baseURL = "https://api.themoviedb.org/3"

    private let readAccessToken: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String else {
            fatalError("TMDBReadAccessToken not found in Info.plist")
        }
        return token
    }()

    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String else {
            fatalError("TMDBAPIKey not found in Info.plist")
        }
        return key
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Accept": "application/json"]
        return URLSession(configuration: config)
    }()

    // MARK: - Search Movies

    struct TMDBSearchResponse: Decodable {
        let page: Int
        let results: [TMDBMovie]
        let totalPages: Int
        let totalResults: Int
    }

    struct TMDBMovie: Decodable, Identifiable {
        let id: Int
        let title: String
        let originalTitle: String?
        let overview: String?
        let posterPath: String?
        let backdropPath: String?
        let releaseDate: String?
        let voteAverage: Double?
        let voteCount: Int?
        let popularity: Double?
        let genreIds: [Int]?

        var posterURL: URL? {
            guard let path = posterPath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
        }

        var backdropURL: URL? {
            guard let path = backdropPath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
        }
    }

    func searchMovies(query: String, page: Int = 1) async throws -> TMDBSearchResponse {
        var components = URLComponents(string: "\(baseURL)/search/movie")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "language", value: "de-DE"),
        ]
        return try await request(url: components.url!)
    }

    // MARK: - Movie Details

    struct TMDBMovieDetail: Decodable, Identifiable {
        let id: Int
        let title: String
        let originalTitle: String?
        let overview: String?
        let posterPath: String?
        let backdropPath: String?
        let releaseDate: String?
        let runtime: Int?
        let voteAverage: Double?
        let voteCount: Int?
        let genres: [TMDBGenre]?
        let imdbId: String?

        var posterURL: URL? {
            guard let path = posterPath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
        }
    }

    struct TMDBGenre: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    func movieDetail(id: Int) async throws -> TMDBMovieDetail {
        let url = URL(string: "\(baseURL)/movie/\(id)?language=de-DE")!
        return try await request(url: url)
    }

    // MARK: - Find by IMDB ID

    struct TMDBFindResponse: Decodable {
        let movieResults: [TMDBMovie]
    }

    func findByIMDBId(_ imdbId: String) async throws -> TMDBFindResponse {
        var components = URLComponents(string: "\(baseURL)/find/\(imdbId)")!
        components.queryItems = [
            URLQueryItem(name: "external_source", value: "imdb_id"),
            URLQueryItem(name: "language", value: "de-DE"),
        ]
        return try await request(url: components.url!)
    }

    // MARK: - Private

    private func request<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(readAccessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw TMDBError.httpError(statusCode: statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

enum TMDBError: LocalizedError {
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "TMDB API returned status \(code)"
        }
    }
}
