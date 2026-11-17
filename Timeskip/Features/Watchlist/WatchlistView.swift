import SwiftUI

// Placeholder: matches the "Empty watchlist" screen in Figma.
struct WatchlistView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Your watchlist is empty",
                systemImage: "bookmark",
                description: Text("Tap “Add to Watchlist” on any title to save it for later.")
            )
            .navigationTitle("Watchlist")
            .background(Theme.background)
        }
    }
}
