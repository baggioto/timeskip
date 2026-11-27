import DesignSystem
import SwiftUI
import TMDBKit

/// The three tabs from the Figma mockups.
struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        @Bindable var router = dependencies.router
        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house", value: Router.Tab.home) {
                TrendingView(service: dependencies.tmdb, cache: dependencies.feedCache)
            }
            Tab("Search", systemImage: "magnifyingglass", value: Router.Tab.search) {
                SearchView(service: dependencies.tmdb, recentStore: dependencies.recentSearches)
            }
            Tab("Watchlist", systemImage: "bookmark", value: Router.Tab.watchlist) {
                WatchlistView(service: dependencies.tmdb)
            }
        }
        // A tab bar on iPhone; on iPad it can turn into a sidebar.
        .tabViewStyle(.sidebarAdaptable)
        .tint(Theme.accent)
        .environment(dependencies.watchlist)
        .environment(dependencies.episodes)
        .environment(dependencies.reminders)
        .environment(dependencies.router)
        .onOpenURL { dependencies.router.open($0) }
    }
}

#Preview {
    RootView(dependencies: AppDependencies(tmdb: PreviewTMDBService()))
        .preferredColorScheme(.dark)
}
