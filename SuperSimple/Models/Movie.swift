import Foundation

struct MovieListResponse: Codable {
    let next: String?
    let contentType: String?
    let title: String?
    let moviesAndTvshows: [Movie]?
    let featuredItem: Movie?

    enum CodingKeys: String, CodingKey {
        case next
        case contentType = "content_type"
        case title
        case moviesAndTvshows = "movies_tvshows"
        case featuredItem = "featured_item"
    }

    var movies: [Movie] {
        moviesAndTvshows ?? []
    }
}

struct Movie: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String?
    let genre: [String]?
    let pgRating: Int?
    let posterURL: String?
    let photoURL: String?
    let summary: String?
    let stats: MovieStats?
    let ratings: MovieRatings?
    let people: [Person]?
    let cinemas: [Cinema]?
    let showtimes: [ShowtimeGroup]?
    let media: [MovieMedia]?

    enum CodingKeys: String, CodingKey {
        case id, title, genre, summary, stats, ratings, people, cinemas, showtimes, media
        case originalTitle = "original_title"
        case pgRating = "pg_rating"
        case posterURL = "poster_url"
        case photoURL = "photo_url"
    }
}

struct MovieStats: Codable {
    let premiereDate: String?
    let premiereYear: String?
    let duration: Int?
    let distributor: String?
    let country: String?
    let languages: [String]?
    let revenue: Double?

    enum CodingKeys: String, CodingKey {
        case duration, distributor, country, languages, revenue
        case premiereDate = "premiere_date"
        case premiereYear = "premiere_year"
    }
}

struct MovieRatings: Codable {
    let popularity: Double?
    let imdbID: String?
    let imdbRating: String?
    let watchlistCount: Int?
    let tmdbPopularity: Double?

    enum CodingKeys: String, CodingKey {
        case popularity
        case imdbID = "imdb_id"
        case imdbRating = "imdb_rating"
        case watchlistCount = "watchlist_count"
        case tmdbPopularity = "tmdb_popularity"
    }
}

struct Person: Codable, Identifiable {
    let id: Int
    let name: String
    let role: String?
    let photoURL: String?
    let characterName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case photoURL = "photo_url"
        case characterName = "character_name"
    }
}

extension Movie {
    var isNewThisWeek: Bool {
        guard let dateString = stats?.premiereDate else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let premiere = formatter.date(from: dateString) else { return false }
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return false }
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return false }
        return premiere >= weekStart && premiere < weekEnd
    }
}

struct MovieMedia: Codable, Identifiable {
    let id: Int
    let name: String?
    let mediaURL: String?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mediaURL = "media_url"
        case photoURL = "photo_url"
    }
}
