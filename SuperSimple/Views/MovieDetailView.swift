import SwiftUI
import AVKit
import AVFoundation

struct MovieDetailView: View {
    let movieID: Int
    @State private var movie: Movie?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showTrailer = false
    @State private var trailerPlayer: AVPlayer?
    @State private var tmdbDetail: TMDBAPIClient.TMDBMovieDetail?
    @State private var isSynopsisExpanded = false

    var body: some View {
        Group {
            if isLoading && movie == nil {
                ProgressView()
            } else if let error, movie == nil {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await load() } }
                }
            } else if let movie {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        headerSection(movie)
                        infoSection(movie)
                        if let summary = movie.summary, !summary.isEmpty {
                            summarySection(summary)
                        }
                        if let showtimes = movie.showtimes, !showtimes.isEmpty,
                           let cinemas = movie.cinemas {
                            showtimesSection(showtimes, cinemas: cinemas)
                        }
                        if let people = movie.people, !people.isEmpty {
                            castSection(people)
                        }
                    }
                }
            }
        }
        .navigationTitle(movie?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    SavedMovies.shared.toggle(movieID)
                } label: {
                    Image(systemName: SavedMovies.shared.isSaved(movieID) ? "star.fill" : "star")
                        .foregroundStyle(SavedMovies.shared.isSaved(movieID) ? .yellow : .secondary)
                }
            }
        }
        .task { await load() }
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

    private func load() async {
        // Show cached data instantly, refresh in background
        if let cached = SavedMovies.shared.movieDetailCache[movieID] {
            movie = cached
        }
        isLoading = true
        error = nil
        do {
            let location = LocationManager.shared.apiLocation ?? .berlin
            let loaded = try await KinoAPIClient.shared.fetchMovieDetail(id: movieID, location: location)
            movie = loaded
            SavedMovies.shared.cacheDetail(loaded)
            if let cinemas = loaded.cinemas {
                SavedMovies.shared.registerCinemas(
                    cinemas.map { SavedMovies.CinemaInfo(id: $0.id, name: $0.displayName, latitude: $0.latitude, longitude: $0.longitude) },
                    forMovie: movieID
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false

        // Fetch TMDB details in background using IMDB ID bridge
        if let imdbID = movie?.ratings?.imdbID {
            Task {
                if let findResult = try? await TMDBAPIClient.shared.findByIMDBId(imdbID),
                   let tmdbMovie = findResult.movieResults.first {
                    let detail = try? await TMDBAPIClient.shared.movieDetail(id: tmdbMovie.id)
                    tmdbDetail = detail
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(_ movie: Movie) -> some View {
        let photoURL = movie.photoURL.flatMap {
            URL(string: $0.replacingOccurrences(of: "/small.", with: "/large."))
        }

        ZStack {
            CachedAsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle().fill(.quaternary)
                default:
                    Rectangle().fill(.quaternary)
                        .overlay(ProgressView())
                }
            }
            .frame(height: 220)
            .clipped()

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }

            if movie.media != nil && !(movie.media?.isEmpty ?? true) {
                Button {
                    Task { await playTrailer(movie) }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 4)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Text(movie.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding()
                    Spacer()
                }
            }
        }
        .frame(height: 220)
        .clipped()
    }

    // MARK: - Info Pills

    private func infoSection(_ movie: Movie) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let duration = movie.stats?.duration {
                    infoPill(icon: "clock", text: "\(duration) min")
                }
                if let country = movie.stats?.country, !country.isEmpty {
                    infoPill(icon: "globe", text: country)
                }
                if let languages = movie.stats?.languages, !languages.isEmpty {
                    infoPill(icon: "text.bubble", text: languages.joined(separator: ", "))
                }
                if let pgRating = movie.pgRating {
                    infoPill(icon: "person.fill", text: "FSK \(pgRating)")
                }
                if let genres = movie.genre {
                    ForEach(genres, id: \.self) { genre in
                        infoPill(icon: "tag", text: genre.capitalized)
                    }
                }
                if let rating = movie.ratings?.imdbRating {
                    infoPill(icon: "star.fill", text: "IMDb \(rating)", tint: .orange)
                }
                if let tmdb = movie.ratings?.tmdbPopularity, tmdb > 0 {
                    infoPill(icon: "chart.line.uptrend.xyaxis", text: "TMDB \(Int(tmdb))%", tint: .green)
                }
                if let budget = tmdbDetail?.budget, budget > 0 {
                    infoPill(icon: "banknote", text: "Budget \(formatRevenue(Double(budget)))")
                }
                if let revenue = movie.stats?.revenue, revenue > 0 {
                    infoPill(icon: "dollarsign.circle", text: formatRevenue(revenue))
                }
                if let watchlist = movie.ratings?.watchlistCount, watchlist > 0 {
                    infoPill(icon: "bookmark.fill", text: "\(watchlist) watchlists", tint: .purple)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func infoPill(icon: String, text: String, tint: Color = .primary) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    // MARK: - Summary

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isSynopsisExpanded ? nil : 5)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSynopsisExpanded.toggle()
                }
            } label: {
                Text(isSynopsisExpanded ? "Show less" : "Read more")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Cast

    private func castSection(_ people: [Person]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cast & Crew")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(people) { person in
                        VStack(spacing: 4) {
                            CachedAsyncImage(url: person.photoURL.flatMap { URL(string: $0) }) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Circle().fill(.quaternary)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(.tertiary)
                                        }
                                }
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())

                            Text(person.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            if let role = person.characterName ?? person.role {
                                Text(role)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 72)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Showtimes

    private func allDateRange(from showtimes: [ShowtimeGroup]) -> [String] {
        let berlinTZ = TimeZone(identifier: "Europe/Berlin")!
        var berlinCalendar = Calendar.current
        berlinCalendar.timeZone = berlinTZ

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = berlinTZ
        let today = formatter.string(from: Date())

        let apiDates = showtimes.map(\.groupDate)
        guard let lastDate = apiDates.max(), let lastParsed = formatter.date(from: lastDate) else {
            return apiDates
        }
        let startParsed = formatter.date(from: today) ?? Date()

        var dates: [String] = []
        var current = startParsed
        while current <= lastParsed {
            dates.append(formatter.string(from: current))
            current = berlinCalendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    private func showtimesSection(_ showtimes: [ShowtimeGroup], cinemas: [Cinema]) -> some View {
        let cinemaMap = Dictionary(cinemas.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let allDates = allDateRange(from: showtimes)

        // Pivot: build cinemaID -> [date: [Showtime]]
        var cinemaDays: [Int: [String: [Showtime]]] = [:]
        var cinemaOrder: [Int] = []
        for group in showtimes {
            for entry in group.groupData {
                if cinemaDays[entry.cinemaID] == nil {
                    cinemaOrder.append(entry.cinemaID)
                    cinemaDays[entry.cinemaID] = [:]
                }
                cinemaDays[entry.cinemaID, default: [:]][group.groupDate] = entry.showtimesData
            }
        }

        // Sort: saved cinemas first, then by distance (closest first)
        let saved = SavedMovies.shared
        let sortedCinemaOrder = cinemaOrder.sorted { a, b in
            let aSaved = saved.isCinemaSaved(a)
            let bSaved = saved.isCinemaSaved(b)
            if aSaved != bSaved { return aSaved }
            let distA = cinemaMap[a].flatMap { c in
                c.latitude.flatMap { lat in c.longitude.flatMap { lon in LocationManager.shared.distance(to: lat, longitude: lon) } }
            } ?? Double.infinity
            let distB = cinemaMap[b].flatMap { c in
                c.latitude.flatMap { lat in c.longitude.flatMap { lon in LocationManager.shared.distance(to: lat, longitude: lon) } }
            } ?? Double.infinity
            return distA < distB
        }

        let columnWidth: CGFloat = 80

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Day header row
                dateHeaderRow(allDates: allDates, columnWidth: columnWidth)
                    .padding(.top, 12)

                // Cinema groups
                ForEach(sortedCinemaOrder, id: \.self) { cinemaID in
                    if let cinema = cinemaMap[cinemaID],
                       let dayMap = cinemaDays[cinemaID] {
                        cinemaHeader(cinema: cinema)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            .contextMenu {
                                Button {
                                    saved.toggleCinema(cinemaID)
                                } label: {
                                    if saved.isCinemaSaved(cinemaID) {
                                        Label("Unsave Cinema", systemImage: "star.slash")
                                    } else {
                                        Label("Save Cinema", systemImage: "star")
                                    }
                                }
                            }

                        // Showtime chips row for this cinema
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(allDates, id: \.self) { date in
                                VStack(spacing: 4) {
                                    if let times = dayMap[date] {
                                        ForEach(times) { showtime in
                                            showtimeChip(showtime)
                                        }
                                    }
                                }
                                .frame(width: columnWidth)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                }

                // Day footer row
                dateHeaderRow(allDates: allDates, columnWidth: columnWidth)
                    .padding(.bottom, 12)
            }
        }
    }

    private func dateHeaderRow(allDates: [String], columnWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(allDates, id: \.self) { date in
                let parts = formatShortDateParts(date)
                VStack(spacing: 1) {
                    Text(parts.day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(parts.date)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .frame(width: columnWidth)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
    }

    private func cinemaHeader(cinema: Cinema) -> some View {
        HStack(spacing: 6) {
            Text(cinema.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            if SavedMovies.shared.isCinemaSaved(cinema.id) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
            if let lat = cinema.latitude, let lon = cinema.longitude,
               let dist = LocationManager.shared.formattedDistance(to: lat, longitude: lon) {
                Text(dist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func showtimeChip(_ showtime: Showtime) -> some View {
        Group {
            if let link = showtime.ticketLink, let url = URL(string: link) {
                Link(destination: url) {
                    showtimeLabel(showtime)
                }
            } else {
                showtimeLabel(showtime)
            }
        }
    }

    private func showtimeLabel(_ showtime: Showtime) -> some View {
        VStack(spacing: 1) {
            Text(showtime.displayTime)
                .font(.caption)
                .fontWeight(.medium)
            if !showtime.displayLabel.isEmpty {
                Text(showtime.displayLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatRevenue(_ revenue: Double) -> String {
        if revenue >= 1_000_000_000 {
            return String(format: "$%.1fB", revenue / 1_000_000_000)
        } else if revenue >= 1_000_000 {
            return String(format: "$%.0fM", revenue / 1_000_000)
        } else if revenue >= 1_000 {
            return String(format: "$%.0fK", revenue / 1_000)
        }
        return String(format: "$%.0f", revenue)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    private func formatShortDateParts(_ dateString: String) -> (day: String, date: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return (dateString, "") }
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        let day = formatter.string(from: date)
        formatter.dateFormat = "dd.MM"
        let dateStr = formatter.string(from: date)
        return (day, dateStr)
    }
}

// MARK: - Trailer Player

struct TrailerPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Configure audio session to ignore silent mode
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        controller.entersFullScreenWhenPlaybackBegins = false
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}


// Simple flow layout for showtime chips
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
