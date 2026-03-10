import SwiftUI
import AVKit

struct MovieListView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedCinemaID: Int?
    @State private var isLoadingCinema = false
    @State private var selectedDate: Date?
    @State private var showTrailer = false
    @State private var trailerPlayer: AVPlayer?

    private static let berlinTimezone = TimeZone(identifier: "Europe/Berlin")!

    private static var berlinCalendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = berlinTimezone
        return cal
    }

    private static var today: Date {
        berlinCalendar.startOfDay(for: Date())
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = berlinTimezone
        return f
    }()

    private var weekDates: [Date] {
        let calendar = Self.berlinCalendar
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
            // When filtered by cinema, sort by earliest showtime date
            if let cinemaID = selectedCinemaID {
                let aFirst = saved.showtimesFromCinema(forMovie: a.id, cinemaID: cinemaID)?.keys.min() ?? "9999"
                let bFirst = saved.showtimesFromCinema(forMovie: b.id, cinemaID: cinemaID)?.keys.min() ?? "9999"
                if aFirst != bFirst { return aFirst < bFirst }
            } else {
                let aNew = a.isNewThisWeek
                let bNew = b.isNewThisWeek
                if aNew != bNew { return aNew }
            }
            return false
        }
    }

    var body: some View {
        Group {
            if isLoading && movies.isEmpty {
                ProgressView("Loading movies...")
            } else if let error, movies.isEmpty {
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
        .fullScreenCover(isPresented: $showTrailer) {
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()
                if let player = trailerPlayer {
                    TrailerPlayerView(player: player)
                        .ignoresSafeArea()
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Button {
                    showTrailer = false
                    trailerPlayer?.pause()
                    trailerPlayer = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .padding()
                }
                .zIndex(1)
            }
        }
    }

    private func playTrailer(_ movie: Movie) async {
        guard let media = movie.media?.first,
              let oEmbedURL = media.mediaURL else { return }
        do {
            if let hlsURL = try await KinoAPIClient.shared.fetchTrailerURL(oEmbedURL: oEmbedURL) {
                let player = AVPlayer(url: hlsURL)
                trailerPlayer = player
                showTrailer = true
            }
        } catch {
            // Silently fail
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
                let isSelected = selectedDate.map { Self.berlinCalendar.isDate(date, inSameDayAs: $0) } ?? false
                let isToday = Self.berlinCalendar.isDate(date, inSameDayAs: Self.today)
                Button {
                    withAnimation {
                        if isSelected {
                            selectedDate = nil
                        } else {
                            selectedDate = date
                        }
                    }
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
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
                        showtimesByDate: selectedCinemaID.flatMap { SavedMovies.shared.showtimesFromCinema(forMovie: movie.id, cinemaID: $0) },
                        isLoadingShowtimes: isLoadingCinema,
                        hasTrailer: movie.media != nil && !(movie.media?.isEmpty ?? true),
                        onPlayTrailer: { Task { await playTrailer(movie) } }
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
            let dateString = selectedDate.map { Self.dayFormatter.string(from: $0) }
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
    var showtimesByDate: [String: [Showtime]]? = nil
    var isLoadingShowtimes: Bool = false
    var hasTrailer: Bool = false
    var onPlayTrailer: (() -> Void)? = nil

    private var sortedDates: [String] {
        guard let byDate = showtimesByDate else { return [] }
        return byDate.keys.sorted()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(url: posterURL) { phase in
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
            .overlay {
                if hasTrailer {
                    Button {
                        onPlayTrailer?()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.4))
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: sortedDates.isEmpty ? .leading : .center, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    if let year = movie.stats?.premiereYear {
                        InfoPill(icon: "calendar", text: year)
                    }
                    if let genres = movie.genre, !genres.isEmpty {
                        Text(genres.map { $0.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isLoadingShowtimes {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Loading times...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !sortedDates.isEmpty {
                    showtimeDateTable
                }
            }
        }
        .padding(.vertical, 4)
    }

    private static var berlinCalendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return cal
    }

    private static var next4Days: [String] {
        let cal = berlinCalendar
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return (0..<4).map { fmt.string(from: cal.date(byAdding: .day, value: $0, to: today)!) }
    }

    private var showsInNext4Days: Bool {
        let upcoming = Set(Self.next4Days)
        return sortedDates.contains { upcoming.contains($0) }
    }

    private var totalShowtimeCount: Int {
        showtimesByDate?.values.reduce(0) { $0 + $1.count } ?? 0
    }

    @ViewBuilder
    private var showtimeDateTable: some View {
        if showsInNext4Days {
            // Show next 4 days as columns, even if some are empty
            let days = Self.next4Days
            HStack(alignment: .top, spacing: 4) {
                ForEach(days, id: \.self) { date in
                    VStack(spacing: 3) {
                        Text(Self.formatCompactDate(date))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        if let times = showtimesByDate?[date] {
                            ForEach(times) { showtime in
                                showtimeCompactChip(showtime)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else if totalShowtimeCount <= 3 {
            // List individual showtimes with full date
            VStack(alignment: .leading, spacing: 4) {
                ForEach(sortedDates, id: \.self) { date in
                    if let times = showtimesByDate?[date] {
                        ForEach(times) { showtime in
                            Text(Self.formatShowtimeLine(date: date, showtime: showtime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Many showtimes far out — just show earliest date
            if let firstDate = sortedDates.first {
                Text("ab \(Self.formatLongDate(firstDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func showtimeCompactChip(_ showtime: Showtime) -> some View {
        VStack(spacing: 0) {
            Text(showtime.displayTime)
                .font(.caption2)
                .fontWeight(.medium)
            if !showtime.displayLabel.isEmpty {
                Text(showtime.displayLabel)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private static func formatCompactDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE dd."
        return formatter.string(from: date)
    }

    private static func formatShowtimeLine(date: String, showtime: Showtime) -> String {
        let formatted = formatLongDate(date)
        let label = showtime.displayLabel.isEmpty ? "" : " \(showtime.displayLabel)"
        return "\(formatted) \(showtime.displayTime)\(label)"
    }

    private static func formatLongDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE, dd. MMM"
        return formatter.string(from: date)
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
