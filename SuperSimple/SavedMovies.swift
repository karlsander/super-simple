import Foundation

@Observable
final class SavedMovies {
    static let shared = SavedMovies()

    private let movieKey = "savedMovieIDs"
    private let cinemaKey = "savedCinemaIDs"
    private(set) var ids: Set<Int>
    private(set) var cinemaIDs: Set<Int>

    private init() {
        ids = Set(UserDefaults.standard.array(forKey: movieKey) as? [Int] ?? [])
        cinemaIDs = Set(UserDefaults.standard.array(forKey: cinemaKey) as? [Int] ?? [])
    }

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
}
