import Foundation

struct ShowtimeGroup: Decodable {
    let groupDate: String
    let groupData: [CinemaShowtimes]

    enum CodingKeys: String, CodingKey {
        case groupDate = "group_date"
        case groupData = "group_data"
    }
}

struct CinemaShowtimes: Decodable {
    let cinemaID: Int
    let showtimesData: [Showtime]

    enum CodingKeys: String, CodingKey {
        case cinemaID = "cinema_id"
        case showtimesData = "showtimes_data"
    }
}

struct Showtime: Decodable, Identifiable {
    let id: Int
    let dateTime: String
    let ticketLink: String?
    let value: String?

    enum CodingKeys: String, CodingKey {
        case id, value
        case dateTime = "date_time"
        case ticketLink = "ticket_link"
    }

    var displayTime: String {
        guard let date = ISO8601DateFormatter().date(from: dateTime) else {
            return value ?? ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    var displayLabel: String {
        if let v = value, !v.isEmpty {
            return v
        }
        return ""
    }
}
