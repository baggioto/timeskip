import Testing

@testable import TMDBKit
@testable import Timeskip

struct DetailsViewModelTests {
    @Test func loadsDetails() async {
        let service = MockTMDBService()
        let title = Fixtures.title(7, .tv)
        let details = TitleDetails(
            title: title, tagline: nil, genres: ["Drama"], runtimeMinutes: 45, cast: [], seasons: [])
        await service.setDetails(.success(details))
        let model = DetailsViewModel(title: title, service: service)

        await model.load()

        #expect(model.state == .loaded(details))
        #expect(model.details?.runtime == "45m")
    }

    @Test func failureShowsError() async {
        let service = MockTMDBService()
        await service.setDetails(.failure(.http(status: 404)))
        let model = DetailsViewModel(title: Fixtures.title(7), service: service)

        await model.load()

        #expect(model.state == .failed(.http(status: 404)))
    }
}

struct WatchlistStoreTests {
    @Test func toggleAddsNewestFirstAndRemoves() {
        let store = WatchlistStore()
        let a = Fixtures.title(1)
        let b = Fixtures.title(2)

        store.toggle(a)
        store.toggle(b)
        #expect(store.items.map(\.id) == [b.id, a.id])

        store.toggle(a)
        #expect(store.items.map(\.id) == [b.id])
        #expect(!store.contains(a.id))
    }

    @Test func addingTwiceKeepsOneCopy() {
        let store = WatchlistStore()
        store.add(Fixtures.title(1))
        store.add(Fixtures.title(1))
        #expect(store.items.count == 1)
    }

    @Test func movieAndShowWithTheSameTMDBIdAreDifferentTitles() {
        let store = WatchlistStore()
        store.add(Fixtures.title(1399, .movie))
        store.add(Fixtures.title(1399, .tv))
        #expect(store.items.count == 2)
    }
}
