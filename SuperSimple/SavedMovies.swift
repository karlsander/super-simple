import Foundation

@Observable
final class SavedMovies {
    static let shared = SavedMovies()

    private let key = "savedMovieIDs"
    private(set) var ids: Set<Int>

    private init() {
        let stored = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        ids = Set(stored)
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
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
