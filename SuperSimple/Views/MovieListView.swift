import SwiftUI

struct MovieListView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedCinemaID: Int?

    private var filteredMovies: [Movie] {
        var base: [Movie]
        if searchText.isEmpty {
            base = movies
        } else {
            let query = searchText.lowercased()
            base = movies.filter { movie in
                movie.title.lowercased().contains(query)
                || movie.originalTitle?.lowercased().contains(query) == true
                || movie.genre?.contains(where: { $0.lowercased().contains(query) }) == true
            }
        }
        if let cinemaID = selectedCinemaID {
            let associations = SavedMovies.shared.movieCinemaIDs
            base = base.filter { movie in
                guard let cinemaSet = associations[movie.id] else { return true }
                return cinemaSet.contains(cinemaID)
            }
        }
        let saved = SavedMovies.shared
        return base.sorted { a, b in
            let aSaved = saved.isSaved(a.id)
            let bSaved = saved.isSaved(b.id)
            if aSaved != bSaved { return aSaved }
            return false
        }
    }

    var body: some View {
        Group {
            if isLoading && movies.isEmpty {
                ProgressView("Loading movies...")
            } else if let error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await loadMovies() }
                    }
                }
            } else {
                movieList
            }
        }
        .navigationTitle("Now Showing")
        .searchable(text: $searchText, prompt: "Search movies")
        .task {
            if movies.isEmpty {
                await loadMovies()
            }
        }
        .onChange(of: selectedCinemaID) {
            if selectedCinemaID != nil {
                Task { await prefetchDetails() }
            }
        }
    }

    private var cinemaFilterBar: some View {
        let cinemas = SavedMovies.shared.savedCinemasSorted
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cinemas, id: \.id) { cinema in
                    let isSelected = selectedCinemaID == cinema.id
                    Button {
                        withAnimation {
                            selectedCinemaID = isSelected ? nil : cinema.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption2)
                            Text(cinema.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .contextMenu {
                        Button {
                            SavedMovies.shared.toggleCinema(cinema.id)
                            if selectedCinemaID == cinema.id {
                                selectedCinemaID = nil
                            }
                        } label: {
                            Label("Unsave Cinema", systemImage: "star.slash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var movieList: some View {
        List {
            if !SavedMovies.shared.savedCinemasSorted.isEmpty {
                cinemaFilterBar
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            ForEach(filteredMovies) { movie in
                NavigationLink(value: movie.id) {
                    MovieRow(
                        movie: movie,
                        isSaved: SavedMovies.shared.isSaved(movie.id),
                        todaysShowtimes: selectedCinemaID.flatMap { SavedMovies.shared.todaysShowtimes(forMovie: movie.id, cinemaID: $0) },
                        isLoadingShowtimes: selectedCinemaID != nil && SavedMovies.shared.movieDetailCache[movie.id] == nil
                    )
                }
                .contextMenu {
                    Button {
                        SavedMovies.shared.toggle(movie.id)
                    } label: {
                        if SavedMovies.shared.isSaved(movie.id) {
                            Label("Unsave", systemImage: "star.slash")
                        } else {
                            Label("Save", systemImage: "star")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var location: KinoAPIClient.Location {
        LocationManager.shared.apiLocation ?? .berlin
    }

    private func loadMovies() async {
        isLoading = true
        error = nil
        do {
            movies = try await KinoAPIClient.shared.fetchAllMovies(location: location)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func prefetchDetails() async {
        let saved = SavedMovies.shared
        let batch = filteredMovies
            .filter { saved.needsFetch($0.id) }
            .prefix(5)

        for movie in batch {
            saved.markFetching(movie.id)
        }

        await withTaskGroup(of: Void.self) { group in
            for movie in batch {
                group.addTask {
                    do {
                        let detail = try await KinoAPIClient.shared.fetchMovieDetail(id: movie.id, location: location)
                        await MainActor.run {
                            saved.cacheDetail(detail)
                            if let cinemas = detail.cinemas {
                                saved.registerCinemas(
                                    cinemas.map { SavedMovies.CinemaInfo(id: $0.id, name: $0.displayName, latitude: $0.latitude, longitude: $0.longitude) },
                                    forMovie: movie.id
                                )
                            }
                        }
                    } catch {
                        // Skip failed fetches
                    }
                }
            }
        }

        // Continue fetching next batch if there are more
        let remaining = filteredMovies.filter { saved.needsFetch($0.id) }
        if !remaining.isEmpty {
            try? await Task.sleep(for: .milliseconds(500))
            await prefetchDetails()
        }
    }

}

struct MovieRow: View {
    let movie: Movie
    var isSaved: Bool = false
    var todaysShowtimes: [Showtime]? = nil
    var isLoadingShowtimes: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                case .failure:
                    posterPlaceholder
                default:
                    Rectangle()
                        .fill(.quaternary)
                        .overlay(ProgressView())
                }
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(movie.title)
                        .font(.headline)
                        .lineLimit(2)
                    if isSaved {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                if let genres = movie.genre, !genres.isEmpty {
                    Text(genres.map { $0.capitalized }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let year = movie.stats?.premiereYear {
                        Label(year, systemImage: "calendar")
                    }
                    if let rating = movie.ratings?.imdbRating {
                        Label(rating, systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let times = todaysShowtimes, !times.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(times) { showtime in
                                Text(showtime.displayTime)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.tint.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                } else if isLoadingShowtimes {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Loading times...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var posterURL: URL? {
        guard let urlString = movie.posterURL else { return nil }
        return URL(string: urlString.replacingOccurrences(of: "/small.", with: "/medium."))
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                Image(systemName: "film")
                    .foregroundStyle(.tertiary)
            }
    }
}
