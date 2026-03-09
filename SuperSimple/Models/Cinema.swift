import Foundation

struct Cinema: Decodable, Identifiable {
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
