import Foundation
import Observation
import TMDBKit

@Observable
final class SearchViewModel {
    enum State: Equatable {
        /// No query: the screen shows recent searches.
        case idle
        case loading
        case results([Title])
        case empty(query: String)
        case failed(APIError)
    }

    /// Bound to the search field. Every change restarts the debounce.
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch()
        }
    }

    private(set) var state: State = .idle
    private(set) var recent: [String]

    private let service: any TMDBService
    private let recentStore: RecentSearchesStore
    private let debounce: Duration
    /// The pending debounce + request. Cancelling it cancels the URLSession task too,
    /// because the request runs inside it (structured concurrency).
    private(set) var searchTask: Task<Void, Never>?

    init(service: any TMDBService, recentStore: RecentSearchesStore, debounce: Duration = .milliseconds(350)) {
        self.service = service
        self.recentStore = recentStore
        self.debounce = debounce
        self.recent = recentStore.all
    }

    /// Return key: search right away and remember the query.
    func submit() {
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else { return }
        recentStore.add(trimmed)
        recent = recentStore.all
        searchTask?.cancel()
        searchTask = Task { await performSearch(trimmed) }
    }

    func useRecent(_ query: String) {
        self.query = query
        submit()
    }

    func removeRecent(_ query: String) {
        recentStore.remove(query)
        recent = recentStore.all
    }

    func clearRecent() {
        recentStore.clear()
        recent = []
    }

    func retry() async {
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else { return }
        await performSearch(trimmed)
    }

    // MARK: - Private

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        searchTask = Task { [debounce] in
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return  // cancelled: the user typed again
            }
            await performSearch(trimmed)
        }
    }

    private func performSearch(_ query: String) async {
        if case .results = state {} else { state = .loading }
        do {
            let page = try await service.search(query, page: 1)
            guard !Task.isCancelled, query == trimmedQuery else { return }
            state = page.items.isEmpty ? .empty(query: query) : .results(page.items)
        } catch {
            // A superseded search is cancelled and dropped here. A `.cancelled` that reaches this point
            // came from somewhere else, and showing it beats leaving a spinner forever.
            guard !Task.isCancelled, query == trimmedQuery else { return }
            state = .failed(error)
        }
    }
}
