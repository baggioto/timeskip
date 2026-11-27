import Foundation
import TMDBKit

/// The composition root: the one place that decides which concrete implementations the app uses.
/// Features receive what they need through their initializers or the environment.
final class AppDependencies {
    let tmdb: any TMDBService
    let watchlist: WatchlistStore
    let episodes: EpisodeTracker
    let reminders: EpisodeReminders
    let recentSearches: RecentSearchesStore
    let feedCache: any FeedCaching
    let router = Router()

    init(
        tmdb: any TMDBService,
        watchlist: WatchlistStore = WatchlistStore(),
        episodes: EpisodeTracker = EpisodeTracker(),
        reminders: EpisodeReminders = EpisodeReminders(),
        recentSearches: RecentSearchesStore = RecentSearchesStore(),
        feedCache: any FeedCaching = NoFeedCache()
    ) {
        self.tmdb = tmdb
        self.watchlist = watchlist
        self.episodes = episodes
        self.reminders = reminders
        self.recentSearches = recentSearches
        self.feedCache = feedCache
    }

    static func live(bundle: Bundle = .main, process: ProcessInfo = .processInfo) -> AppDependencies {
        #if DEBUG
            // UI tests ask for canned data; unit tests run inside the app and must not touch the real store.
            let isUnitTestHost = process.environment["XCTestConfigurationFilePath"] != nil
            if process.arguments.contains(uiTestingArgument) || isUnitTestHost {
                return uiTesting(feedPages: process.arguments.contains(largeFeedArgument) ? 10 : 1)
            }
        #endif

        let service: any TMDBService =
            AppConfig.fromBundle(bundle)
            .map { TMDBClient(token: $0.tmdbReadToken) } ?? UnconfiguredTMDBService()
        // One SwiftData store for the watchlist and episode tracking.
        let container = WatchlistStore.makeContainer(inMemory: false)
        return AppDependencies(
            tmdb: service,
            watchlist: WatchlistStore(container: container),
            episodes: EpisodeTracker(container: container, publisher: WidgetUpNextPublisher()),
            feedCache: FeedCache()
        )
    }

    static let uiTestingArgument = "-ui-testing"
    /// With `-ui-testing`: a 10-page Trending feed, for the scroll performance test.
    static let largeFeedArgument = "-ui-testing-large-feed"

    #if DEBUG
        /// Canned data, nothing persisted: every UI test starts from the same state, without a network.
        /// Debug only, like `PreviewTMDBService`: Release builds never ship the canned data.
        private static func uiTesting(feedPages: Int) -> AppDependencies {
            AppDependencies(
                tmdb: PreviewTMDBService(feedPages: feedPages),
                recentSearches: RecentSearchesStore(
                    defaults: UserDefaults(suiteName: "ui-testing-\(UUID().uuidString)")!)
            )
        }
    #endif
}
