import SwiftUI

struct MovieListView: View {
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var nextOffset: Int? = 0

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
        .task {
            if movies.isEmpty {
                await loadMovies()
            }
        }
    }

    private var movieList: some View {
        List {
            ForEach(movies) { movie in
                NavigationLink(value: movie.id) {
                    MovieRow(movie: movie)
                }
            }

            if nextOffset != nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .task {
                        await loadMore()
                    }
            }
        }
        .listStyle(.plain)
    }

    private func loadMovies() async {
        isLoading = true
        error = nil
        do {
            let response = try await KinoAPIClient.shared.fetchMovies(offset: 0)
            movies = response.movies
            nextOffset = parseOffset(from: response.next)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard let offset = nextOffset else { return }
        do {
            let response = try await KinoAPIClient.shared.fetchMovies(offset: offset)
            movies.append(contentsOf: response.movies)
            nextOffset = parseOffset(from: response.next)
        } catch {
            // Silently fail on pagination errors
        }
    }

    private func parseOffset(from next: String?) -> Int? {
        guard let next, let components = URLComponents(string: next),
              let offsetItem = components.queryItems?.first(where: { $0.name == "offset" }),
              let value = offsetItem.value else {
            return nil
        }
        return Int(value)
    }
}

struct MovieRow: View {
    let movie: Movie

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
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let genres = movie.genre, !genres.isEmpty {
                    Text(genres.map { $0.capitalized }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let duration = movie.stats?.duration {
                        Label("\(duration) min", systemImage: "clock")
                    }
                    if let rating = movie.ratings?.imdbRating {
                        Label(rating, systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let pgRating = movie.pgRating {
                    Text("FSK \(pgRating)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
