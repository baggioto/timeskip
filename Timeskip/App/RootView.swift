import SwiftUI

/// The three tabs from the Figma mockups (MVP v0.1).
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                TrendingView()
            }
            Tab("Search", systemImage: "magnifyingglass") {
                SearchView()
            }
            Tab("Watchlist", systemImage: "bookmark") {
                WatchlistView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
