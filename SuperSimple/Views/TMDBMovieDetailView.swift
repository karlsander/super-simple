import SwiftUI

struct TMDBMovieDetailView: View {
    let movieID: Int
    @State private var movie: TMDBAPIClient.TMDBMovieDetail?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await load() } }
                }
            } else if let movie {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection(movie)
                        infoSection(movie)
                        if let overview = movie.overview, !overview.isEmpty {
                            summarySection(overview)
                        }
                    }
                }
            }
        }
        .navigationTitle(movie?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            movie = try await TMDBAPIClient.shared.movieDetail(id: movieID)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(_ movie: TMDBAPIClient.TMDBMovieDetail) -> some View {
        let backdropURL = movie.posterPath.flatMap {
            URL(string: "https://image.tmdb.org/t/p/w780\($0)")
        }

        ZStack {
            CachedAsyncImage(url: backdropURL) { phase in
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

    // MARK: - Info

    private func infoSection(_ movie: TMDBAPIClient.TMDBMovieDetail) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let date = movie.releaseDate, !date.isEmpty {
                    infoPill(icon: "calendar", text: String(date.prefix(4)))
                }
                if let runtime = movie.runtime, runtime > 0 {
                    infoPill(icon: "clock", text: "\(runtime) min")
                }
                if let rating = movie.voteAverage, rating > 0 {
                    infoPill(icon: "star.fill", text: String(format: "%.1f", rating), tint: .orange)
                }
                if let votes = movie.voteCount, votes > 0 {
                    infoPill(icon: "hand.thumbsup", text: "\(votes) votes")
                }
                if let genres = movie.genres {
                    ForEach(genres) { genre in
                        infoPill(icon: "tag", text: genre.name)
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
