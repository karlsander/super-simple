import Foundation

struct Cinema: Codable, Identifiable {
    let id: Int
    let name: String
    let shortName: String?
    let address: String?
    let city: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    let defaultURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, phone, latitude, longitude
        case shortName = "short_name"
        case defaultURL = "default_url"
    }

    var displayName: String {
        shortName ?? name
    }
}

struct CinemaDetail: Codable {
    let id: Int
    let name: String
    let showtimes: [CinemaMovieShowtimes]

    struct CinemaMovieShowtimes: Codable {
        let movieID: Int
        let showtimesData: [Showtime]

        enum CodingKeys: String, CodingKey {
            case movieID = "movie_id"
            case showtimesData = "showtimes_data"
        }
    }
}
