//
//  ContentView.swift
//  SuperSimple
//
//  Created by Andreas Sander on 17.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            MovieListView(searchText: $searchText)
                .navigationDestination(for: Int.self) { movieID in
                    MovieDetailView(movieID: movieID)
                }
        }
        .searchable(text: $searchText, prompt: "Search movies")
    }
}

#Preview {
    ContentView()
}
