//
//  ContentView.swift
//  SuperSimple
//
//  Created by Andreas Sander on 17.01.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MovieListView()
                .navigationDestination(for: Int.self) { movieID in
                    MovieDetailView(movieID: movieID)
                }
        }
    }
}

#Preview {
    ContentView()
}
