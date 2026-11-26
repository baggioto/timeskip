import Testing

@testable import TMDBKit
@testable import Timeskip

struct TrendingViewModelTests {
    @Test func firstLoadShowsItems() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(1...20, page: 1, of: 3)])
        let model = TrendingViewModel(service: service)

        await model.loadIfNeeded()

        #expect(model.state == .loaded)
        #expect(model.items.count == 20)
        #expect(model.canLoadMore)
    }

    @Test func loadIfNeededOnlyLoadsOnce() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(1...20, page: 1, of: 1)])
        let model = TrendingViewModel(service: service)

        await model.loadIfNeeded()
        await model.loadIfNeeded()

        #expect(await service.trendingCalls.count == 1)
    }

    @Test func nearingTheEndLoadsTheNextPageAndSkipsDuplicates() async {
        let service = MockTMDBService()
        // Page 2 repeats 19 and 20, like TMDB does when trending shifts mid-scroll.
        await service.setTrending([
            1: Fixtures.page(1...20, page: 1, of: 2),
            2: Fixtures.page(19...38, page: 2, of: 2),
        ])
        let model = TrendingViewModel(service: service)
        await model.loadIfNeeded()

        await model.loadMoreIfNeeded(after: model.items[2])  // far from the end: nothing
        #expect(await service.trendingCalls.count == 1)

        await model.loadMoreIfNeeded(after: model.items[16])  // within the prefetch distance
        #expect(model.items.count == 38)
        #expect(Set(model.items.map(\.id)).count == 38)
        #expect(!model.canLoadMore)

        await model.loadMore()  // last page reached: nothing
        #expect(await service.trendingCalls.count == 2)
    }

    @Test func firstPageFailureShowsFullScreenError() async {
        let service = MockTMDBService()
        await service.setTrendingError(.offline)
        let model = TrendingViewModel(service: service)

        await model.loadIfNeeded()

        #expect(model.state == .failed(.offline))
    }

    @Test func refreshFailureKeepsContent() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(1...20, page: 1, of: 2)])
        let model = TrendingViewModel(service: service)
        await model.loadIfNeeded()

        await service.setTrendingError(.offline)
        await model.reload()

        #expect(model.state == .loaded)
        #expect(model.items.count == 20)
        #expect(model.refreshError == .offline)
    }

    @Test func switchingWindowReloadsFromPageOne() async {
        let service = MockTMDBService()
        await service.setTrending([1: Fixtures.page(1...20, page: 1, of: 2)])
        let model = TrendingViewModel(service: service)
        await model.loadIfNeeded()

        await model.select(.week)

        let calls = await service.trendingCalls
        #expect(calls.map(\.0) == [.day, .week])
        #expect(calls.map(\.1) == [1, 1])
        #expect(model.window == .week)
    }

    @Test func emptyResponseShowsEmptyState() async {
        let service = MockTMDBService()
        await service.setTrending([1: Page(items: [], page: 1, totalPages: 1)])
        let model = TrendingViewModel(service: service)

        await model.loadIfNeeded()

        #expect(model.state == .empty)
    }
}
