import Foundation
import Testing

@testable import TMDBKit
@testable import Timeskip

struct SearchViewModelTests {
    private func makeModel(_ service: MockTMDBService, debounce: Duration = .milliseconds(50))
        -> (SearchViewModel, RecentSearchesStore)
    {
        let defaults = UserDefaults(suiteName: "SearchViewModelTests-\(UUID().uuidString)")!
        let store = RecentSearchesStore(defaults: defaults)
        return (SearchViewModel(service: service, recentStore: store, debounce: debounce), store)
    }

    @Test func typingQuicklySendsOnlyTheLastQuery() async {
        let service = MockTMDBService()
        await service.setSearch(["dune": [Fixtures.title(1, name: "Dune")]])
        let (model, _) = makeModel(service)

        model.query = "d"
        model.query = "du"
        model.query = "dun"
        model.query = "dune"
        await model.searchTask?.value

        #expect(await service.searchCalls == ["dune"])
        #expect(model.state == .results([Fixtures.title(1, name: "Dune")]))
    }

    @Test func clearingTheQueryCancelsAndGoesIdle() async {
        let service = MockTMDBService()
        let (model, _) = makeModel(service)

        model.query = "dune"
        model.query = ""
        await model.searchTask?.value

        #expect(await service.searchCalls.isEmpty)
        #expect(model.state == .idle)
    }

    @Test func whitespaceOnlyDoesNotSearch() async {
        let service = MockTMDBService()
        let (model, _) = makeModel(service)

        model.query = "   "
        await model.searchTask?.value

        #expect(await service.searchCalls.isEmpty)
        #expect(model.state == .idle)
    }

    @Test func noResultsShowsEmptyState() async {
        let service = MockTMDBService()
        let (model, _) = makeModel(service)

        model.query = "zzzz"
        await model.searchTask?.value

        #expect(model.state == .empty(query: "zzzz"))
    }

    @Test func errorsAreShown() async {
        let service = MockTMDBService()
        await service.setSearchError(.offline)
        let (model, _) = makeModel(service)

        model.query = "dune"
        await model.searchTask?.value

        #expect(model.state == .failed(.offline))
    }

    @Test func strayCancellationNeverLeavesASpinner() async {
        let service = MockTMDBService()
        await service.setSearchError(.cancelled)
        let (model, _) = makeModel(service)

        model.query = "dune"
        await model.searchTask?.value

        #expect(model.state != .loading)
    }

    @Test func submitSearchesImmediatelyAndRemembersTheQuery() async {
        let service = MockTMDBService()
        let (model, store) = makeModel(service, debounce: .seconds(10))

        model.query = "  Severance "
        model.submit()
        await model.searchTask?.value

        #expect(await service.searchCalls == ["Severance"])
        #expect(store.all == ["Severance"])
        #expect(model.recent == ["Severance"])
    }
}

struct RecentSearchesStoreTests {
    private func makeStore(limit: Int = 3) -> RecentSearchesStore {
        RecentSearchesStore(defaults: UserDefaults(suiteName: "Recent-\(UUID().uuidString)")!, limit: limit)
    }

    @Test func newestFirstWithoutDuplicates() {
        let store = makeStore()
        store.add("dune")
        store.add("alien")
        store.add("DUNE")
        #expect(store.all == ["DUNE", "alien"])
    }

    @Test func keepsOnlyTheLimit() {
        let store = makeStore(limit: 3)
        ["a", "b", "c", "d"].forEach(store.add)
        #expect(store.all == ["d", "c", "b"])
    }

    @Test func removeAndClear() {
        let store = makeStore()
        store.add("a")
        store.add("b")
        store.remove("a")
        #expect(store.all == ["b"])
        store.clear()
        #expect(store.all.isEmpty)
    }
}
