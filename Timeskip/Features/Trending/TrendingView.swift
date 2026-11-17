import SwiftUI

// Placeholder: the trending feed (API client + pagination) is the first v0.1 feature.
struct TrendingView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Trending is coming",
                systemImage: "film.stack",
                description: Text(AppConfig.fromBundle() == nil
                    ? "Add your TMDB token to Config/Secrets.xcconfig."
                    : "TMDB token found. Next step: the API client.")
            )
            .navigationTitle("Timeskip")
            .background(Theme.background)
        }
    }
}
