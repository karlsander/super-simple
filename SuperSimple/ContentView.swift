import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "sparkles")
                .imageScale(.large)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
