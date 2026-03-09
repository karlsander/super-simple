import SwiftUI

struct TMDBSearchView: View {
    @State private var searchText = ""
    @State private var results: [TMDBAPIClient.TMDBMovie] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        Group {
            if !hasSearched && results.isEmpty {
                ContentUnavailableView("Search TMDB", systemImage: "magnifyingglass", description: Text("Find any movie in The Movie Database"))
            } else if results.isEmpty && hasSearched && !isSearching {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(results) { movie in
                    NavigationLink {
                        TMDBMovieDetailView(movieID: movie.id)
                    } label: {
                        TMDBMovieRow(movie: movie)
                    }
                }
                .listStyle(.plain)
            }
        }
        .overlay {
            if isSearching && results.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Movie title...")
        .onSubmit(of: .search) {
            performSearch()
        }
        .onChange(of: searchText) {
            guard !searchText.isEmpty else {
                results = []
                hasSearched = false
                return
            }
            // Debounce: wait 500ms after typing stops
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                performSearch()
            }
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        Task {
            isSearching = true
            do {
                let response = try await TMDBAPIClient.shared.searchMovies(query: query)
                results = response.results
            } catch {
                // Keep previous results on error
            }
            hasSearched = true
            isSearching = false
        }
    }
}

private struct TMDBMovieRow: View {
    let movie: TMDBAPIClient.TMDBMovie

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: movie.posterURL) { phase in
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
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let date = movie.releaseDate, !date.isEmpty {
                    Text(String(date.prefix(4)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rating = movie.voteAverage, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", rating))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let overview = movie.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
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
