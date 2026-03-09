import Foundation

@Observable
final class SavedMovies {
    static let shared = SavedMovies()

    private let movieKey = "savedMovieIDs"
    private let cinemaKey = "savedCinemaIDs"
    private let cinemaInfoKey = "cinemaInfoCache"
    private(set) var ids: Set<Int>
    private(set) var cinemaIDs: Set<Int>
    private(set) var cinemaInfo: [Int: CinemaInfo] = [:]

    // Movie -> cinema associations (populated from detail views)
    private(set) var movieCinemaIDs: [Int: Set<Int>] = [:]

    struct CinemaInfo: Codable {
        let id: Int
        let name: String
        let latitude: Double?
        let longitude: Double?
    }

    private init() {
        ids = Set(UserDefaults.standard.array(forKey: movieKey) as? [Int] ?? [])
        cinemaIDs = Set(UserDefaults.standard.array(forKey: cinemaKey) as? [Int] ?? [])
        if let data = UserDefaults.standard.data(forKey: cinemaInfoKey),
           let cached = try? JSONDecoder().decode([CinemaInfo].self, from: data) {
            cinemaInfo = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })
        }
    }

    // MARK: - Movies

    func isSaved(_ id: Int) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: Int) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        UserDefaults.standard.set(Array(ids), forKey: movieKey)
    }

    // MARK: - Cinemas

    func isCinemaSaved(_ id: Int) -> Bool {
        cinemaIDs.contains(id)
    }

    func toggleCinema(_ id: Int) {
        if cinemaIDs.contains(id) {
            cinemaIDs.remove(id)
        } else {
            cinemaIDs.insert(id)
        }
        UserDefaults.standard.set(Array(cinemaIDs), forKey: cinemaKey)
    }

    func registerCinemas(_ cinemas: [CinemaInfo], forMovie movieID: Int) {
        var changed = false
        for cinema in cinemas {
            if cinemaInfo[cinema.id] == nil {
                cinemaInfo[cinema.id] = cinema
                changed = true
            }
        }
        movieCinemaIDs[movieID] = Set(cinemas.map(\.id))
        if changed {
            let data = try? JSONEncoder().encode(Array(cinemaInfo.values))
            UserDefaults.standard.set(data, forKey: cinemaInfoKey)
        }
    }

    var savedCinemasSorted: [CinemaInfo] {
        cinemaIDs.compactMap { cinemaInfo[$0] }
            .sorted { a, b in
                let distA = a.latitude.flatMap { lat in a.longitude.flatMap { lon in LocationManager.shared.distance(to: lat, longitude: lon) } } ?? Double.infinity
                let distB = b.latitude.flatMap { lat in b.longitude.flatMap { lon in LocationManager.shared.distance(to: lat, longitude: lon) } } ?? Double.infinity
                return distA < distB
            }
    }
}
