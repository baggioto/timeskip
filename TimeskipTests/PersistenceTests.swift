import Foundation
import Testing

@testable import TMDBKit
@testable import Timeskip

struct WatchlistPersistenceTests {
    @Test func savedTitlesSurviveARelaunch() {
        let container = WatchlistStore.makeContainer(inMemory: true)
        let first = WatchlistStore(container: container)
        first.add(Fixtures.title(1))
        first.add(Fixtures.title(2, .tv))

        // A second store on the same container plays the part of the next app launch.
        let relaunched = WatchlistStore(container: container)

        #expect(relaunched.items.map(\.id) == [Fixtures.title(2, .tv).id, Fixtures.title(1).id])
        #expect(relaunched.items.first?.name == "Title 2")
    }

    @Test func removalIsPersisted() {
        let container = WatchlistStore.makeContainer(inMemory: true)
        let store = WatchlistStore(container: container)
        store.add(Fixtures.title(1))
        store.add(Fixtures.title(2))
        store.remove(atOffsets: IndexSet(integer: 0))  // the newest: title 2

        #expect(WatchlistStore(container: container).items.map(\.id) == [Fixtures.title(1).id])
    }
}

struct FeedCacheTests {
    private func makeCache(now: Date = Date(timeIntervalSince1970: 1_000)) -> (FeedCache, URL) {
        let directory = FileManager.default.temporaryDirectory.appending(path: "FeedCacheTests-\(UUID().uuidString)")
        return (FeedCache(directory: directory, now: { now }), directory)
    }

    @Test func roundTripsPerWindow() {
        let (cache, directory) = makeCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        cache.save([Fixtures.title(1), Fixtures.title(2, .tv)], for: .day)

        #expect(
            cache.load(.day)
                == CachedFeed(
                    items: [Fixtures.title(1), Fixtures.title(2, .tv)],
                    savedAt: Date(timeIntervalSince1970: 1_000)))
        #expect(cache.load(.week) == nil)
    }

    @Test func emptyPagesAreNotSaved() {
        let (cache, directory) = makeCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        cache.save([Fixtures.title(1)], for: .day)
        cache.save([], for: .day)

        #expect(cache.load(.day)?.items.count == 1)
    }
}

/// In-memory stand-in for `FeedCache`.
final class MemoryFeedCache: FeedCaching {
    var feeds: [TimeWindow: CachedFeed] = [:]
    func load(_ window: TimeWindow) -> CachedFeed? { feeds[window] }
    func save(_ items: [Title], for window: TimeWindow) {
        feeds[window] = CachedFeed(items: items, savedAt: Date(timeIntervalSince1970: 2_000))
    }
}

struct TrendingOfflineTests {
    @Test func successfulLoadSavesTheFirstPage() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(1...20, page: 1, of: 2)])
        let cache = MemoryFeedCache()
        let model = TrendingViewModel(service: service, cache: cache)

        await model.loadIfNeeded()

        #expect(cache.feeds[.day]?.items.count == 20)
        #expect(model.cachedAt == nil)
    }

    @Test func offlineLaunchShowsTheSavedFeedWithANotice() async {
        let service = MockTMDBService()
        await service.setTrendingError(.offline)
        let cache = MemoryFeedCache()
        cache.feeds[.day] = CachedFeed(
            items: [Fixtures.title(1), Fixtures.title(2)], savedAt: Date(timeIntervalSince1970: 5))
        let model = TrendingViewModel(service: service, cache: cache)

        await model.loadIfNeeded()

        #expect(model.state == .loaded)
        #expect(model.items.count == 2)
        #expect(model.cachedAt == Date(timeIntervalSince1970: 5))
        #expect(model.refreshError == .offline)
        #expect(!model.canLoadMore)  // page count is unknown for a saved feed
    }

    @Test func freshResponseReplacesTheSavedFeed() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(10...29, page: 1, of: 3)])
        let cache = MemoryFeedCache()
        cache.feeds[.day] = CachedFeed(items: [Fixtures.title(1)], savedAt: .distantPast)
        let model = TrendingViewModel(service: service, cache: cache)

        await model.loadIfNeeded()

        #expect(model.items.first?.id == Fixtures.title(10).id)
        #expect(model.cachedAt == nil)
        #expect(model.canLoadMore)
    }

    @Test func offlineWithoutASavedFeedIsAFullScreenError() async {
        let service = MockTMDBService()
        await service.setTrendingError(.offline)
        let model = TrendingViewModel(service: service, cache: MemoryFeedCache())

        await model.loadIfNeeded()

        #expect(model.state == .failed(.offline))
    }
}
