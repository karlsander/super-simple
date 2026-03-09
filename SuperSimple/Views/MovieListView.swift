import SwiftUI

struct MovieListView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedCinemaID: Int?
    @State private var isLoadingCinema = false
    @State private var selectedDate: Date = Self.today

    private static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        return f
    }()

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Self.today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

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
            let sm = SavedMovies.shared
            if sm.hasCinemaDetail(cinemaID) {
                base = base.filter { sm.moviePlaysAtCinema($0.id, cinemaID: cinemaID) }
            }
        }
        let saved = SavedMovies.shared
        return base.sorted { a, b in
            let aSaved = saved.isSaved(a.id)
            let bSaved = saved.isSaved(b.id)
            if aSaved != bSaved { return aSaved }
            let aNew = a.isNewThisWeek
            let bNew = b.isNewThisWeek
            if aNew != bNew { return aNew }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                dayPickerBar
            }
        }
        .searchable(text: $searchText, prompt: "Search movies")
        .task {
            if movies.isEmpty {
                await loadMovies()
            }
        }
        .onChange(of: selectedDate) {
            Task { await loadMovies() }
        }
        .onChange(of: selectedCinemaID) {
            if let cinemaID = selectedCinemaID, !SavedMovies.shared.hasCinemaDetail(cinemaID) {
                Task { await fetchCinemaDetail(cinemaID) }
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

    private var dayPickerBar: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday = Calendar.current.isDate(date, inSameDayAs: Self.today)
                Button {
                    withAnimation { selectedDate = date }
                } label: {
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                        Text(date.formatted(.dateTime.day()))
                            .font(.callout)
                            .fontWeight(isSelected ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.accentColor : .clear)
                    .foregroundStyle(isSelected ? .white : isToday ? Color.accentColor : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
                        isNewRelease: movie.isNewThisWeek,
                        todaysShowtimes: selectedCinemaID.flatMap { SavedMovies.shared.showtimesFromCinema(forMovie: movie.id, cinemaID: $0) },
                        isLoadingShowtimes: isLoadingCinema
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
            let dateString = Self.dayFormatter.string(from: selectedDate)
            movies = try await KinoAPIClient.shared.fetchAllMovies(location: location, date: dateString)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchCinemaDetail(_ cinemaID: Int) async {
        isLoadingCinema = true
        do {
            let detail = try await KinoAPIClient.shared.fetchCinemaDetail(id: cinemaID)
            SavedMovies.shared.registerCinemaDetail(detail)
        } catch {
            // Silently fail — filter will show all movies if no cinema data
        }
        isLoadingCinema = false
    }

}

struct MovieRow: View {
    let movie: Movie
    var isSaved: Bool = false
    var isNewRelease: Bool = false
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
            .overlay(alignment: .topLeading) {
                if isSaved {
                    SaveBanner()
                } else if isNewRelease {
                    NewReleaseBanner()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let genres = movie.genre, !genres.isEmpty {
                    Text(genres.map { $0.capitalized }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let year = movie.stats?.premiereYear {
                        InfoPill(icon: "calendar", text: year)
                    }
                    if let rating = movie.ratings?.imdbRating {
                        InfoPill(icon: "star.fill", text: rating, iconColor: .orange)
                    }
                }

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

private struct InfoPill: View {
    let icon: String
    let text: String
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(iconColor ?? .secondary)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.secondary.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct SaveBanner: View {
    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: size.width, y: 0))
                p.addLine(to: CGPoint(x: 0, y: size.height))
                p.closeSubpath()
            }
            context.fill(path, with: .color(.yellow.opacity(0.85)))

            let starSize: CGFloat = 10
            let offset = size.width * 0.28
            let resolved = context.resolve(
                Text(Image(systemName: "star.fill"))
                    .font(.system(size: starSize))
                    .foregroundColor(.black.opacity(0.7))
            )
            context.draw(resolved, at: CGPoint(x: offset, y: offset))
        }
        .frame(width: 32, height: 32)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 8
            )
        )
    }
}

private struct NewReleaseBanner: View {
    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: size.width, y: 0))
                p.addLine(to: CGPoint(x: 0, y: size.height))
                p.closeSubpath()
            }
            context.fill(path, with: .color(.green.opacity(0.85)))

            let iconSize: CGFloat = 10
            let offset = size.width * 0.28
            let resolved = context.resolve(
                Text(Image(systemName: "sparkles"))
                    .font(.system(size: iconSize))
                    .foregroundColor(.white.opacity(0.9))
            )
            context.draw(resolved, at: CGPoint(x: offset, y: offset))
        }
        .frame(width: 32, height: 32)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 8
            )
        )
    }
}
