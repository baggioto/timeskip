import SwiftUI

// Placeholder: search with debounce + cancellation comes in v0.1.
struct SearchView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Coming in v0.1."))
                .navigationTitle("Search")
                .background(Theme.background)
        }
    }
}
