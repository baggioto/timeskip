import Foundation
import Observation
import TMDBKit

@Observable
final class TrendingViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(APIError)
    }

    private(set) var items: [Title] = []
    private(set) var state: State = .idle
    private(set) var isLoadingMore = false
    /// A failed "next page" keeps the items on screen and shows a retry row instead of a full error.
    private(set) var loadMoreError: APIError?
    /// A failed reload over existing content (pull to refresh, or the network call after showing the cache).
    private(set) var refreshError: APIError?
    /// Set while the grid shows the saved feed instead of a fresh response.
    private(set) var cachedAt: Date?
    private(set) var window: TimeWindow = .day

    private let service: any TMDBService
    private let cache: any FeedCaching
    private var page = 0
    private var totalPages = 1
    /// Bumped on every reload so a slow response for an old window or page is dropped.
    private var generation = 0
    /// How close to the end of the list the next page starts loading.
    private let prefetchDistance = 6

    init(service: any TMDBService, cache: any FeedCaching = NoFeedCache()) {
        self.service = service
        self.cache = cache
    }

    var canLoadMore: Bool { state == .loaded && cachedAt == nil && page < totalPages }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await reload()
    }

    func select(_ newWindow: TimeWindow) async {
        guard newWindow != window else { return }
        window = newWindow
        items = []
        cachedAt = nil
        state = .idle
        await reload()
    }

    func reload() async {
        generation += 1
        let current = generation
        loadMoreError = nil
        refreshError = nil
        isLoadingMore = false
        if items.isEmpty { showCacheOrSpinner() }

        do {
            let result = try await service.trending(window, page: 1)
            guard current == generation else { return }
            items = Self.unique(result.items)
            page = result.page
            totalPages = result.totalPages
            cachedAt = nil
            state = items.isEmpty ? .empty : .loaded
            cache.save(items, for: window)
        } catch {
            guard current == generation, error != .cancelled else { return }
            // Failing over existing content (fresh or cached) keeps it on screen with a notice.
            if items.isEmpty { state = .failed(error) } else { refreshError = error }
        }
    }

    /// Call from each cell's `onAppear`; loads the next page when the user nears the end.
    func loadMoreIfNeeded(after item: Title) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
            index >= items.count - prefetchDistance
        else { return }
        await loadMore()
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        loadMoreError = nil
        let current = generation

        do {
            let result = try await service.trending(window, page: page + 1)
            guard current == generation else { return }
            // TMDB's trending pages shift while you scroll, so the same title can show up twice.
            let known = Set(items.map(\.id))
            items += Self.unique(result.items).filter { !known.contains($0.id) }
            page = result.page
            totalPages = result.totalPages
        } catch {
            if current == generation, error != .cancelled { loadMoreError = error }
        }
        if current == generation { isLoadingMore = false }
    }

    private func showCacheOrSpinner() {
        guard let saved = cache.load(window), !saved.items.isEmpty else {
            state = .loading
            return
        }
        items = saved.items
        cachedAt = saved.savedAt
        state = .loaded
    }

    private static func unique(_ titles: [Title]) -> [Title] {
        var seen = Set<TitleID>()
        return titles.filter { seen.insert($0.id).inserted }
    }
}
