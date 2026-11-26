import Foundation
import Testing
import UserNotifications

@testable import TMDBKit
@testable import Timeskip

private func episode(_ season: Int, _ number: Int, airDate: String? = "2020-01-01") -> Episode {
    Episode(
        id: season * 100 + number, seasonNumber: season, number: number, name: "E\(number)", overview: "",
        airDate: airDate, stillPath: nil, runtimeMinutes: 50)
}

private let show = Fixtures.title(1399, .tv, name: "Game of Thrones")
private let seasons = [
    Season(id: 0, number: 0, name: "Specials", episodeCount: 5, airDate: nil, posterPath: nil),
    Season(id: 1, number: 1, name: "Season 1", episodeCount: 3, airDate: nil, posterPath: nil),
    Season(id: 2, number: 2, name: "Season 2", episodeCount: 2, airDate: nil, posterPath: nil),
]

struct EpisodeTrackerTests {
    @Test func toggleMarksAndUnmarks() {
        let tracker = EpisodeTracker()

        tracker.toggle(episode(1, 1), show: show, seasons: seasons)
        #expect(tracker.isWatched(showID: 1399, season: 1, episode: 1))
        #expect(tracker.watchedCount(showID: 1399, season: 1) == 1)

        tracker.toggle(episode(1, 1), show: show, seasons: seasons)
        #expect(!tracker.isWatched(showID: 1399, season: 1, episode: 1))
    }

    @Test func upNextFollowsTheFurthestWatchedEpisodeAcrossSeasons() {
        let tracker = EpisodeTracker()

        tracker.toggle(episode(1, 1), show: show, seasons: seasons)
        #expect(tracker.upNext.first?.season == 1)
        #expect(tracker.upNext.first?.episode == 2)

        tracker.toggleSeason([episode(1, 1), episode(1, 2), episode(1, 3)], show: show, seasons: seasons)
        let item = tracker.upNext.first
        #expect(item?.season == 2)
        #expect(item?.episode == 1)
        #expect(item?.watched == 3)
        #expect(item?.total == 5)  // Specials don't count
    }

    @Test func caughtUpShowsLeaveUpNext() {
        let tracker = EpisodeTracker()
        tracker.toggleSeason([episode(1, 1), episode(1, 2), episode(1, 3)], show: show, seasons: seasons)
        tracker.toggleSeason([episode(2, 1), episode(2, 2)], show: show, seasons: seasons)

        #expect(tracker.upNext.isEmpty)
    }

    @Test func markSeasonSkipsUnairedEpisodesAndTogglesBack() {
        let tracker = EpisodeTracker()
        let now = Date(timeIntervalSince1970: 1_700_000_000)  // Nov 2023
        let season2 = [episode(2, 1, airDate: "2023-01-01"), episode(2, 2, airDate: "2030-01-01")]

        tracker.toggleSeason(season2, show: show, seasons: seasons, now: now)
        #expect(tracker.isWatched(showID: 1399, season: 2, episode: 1))
        #expect(!tracker.isWatched(showID: 1399, season: 2, episode: 2))

        tracker.toggleSeason(season2, show: show, seasons: seasons, now: now)
        #expect(tracker.watchedCount(showID: 1399, season: 2) == 0)
    }

    @Test func progressSurvivesARelaunch() {
        let container = WatchlistStore.makeContainer(inMemory: true)
        EpisodeTracker(container: container).toggle(episode(1, 2), show: show, seasons: seasons)

        let relaunched = EpisodeTracker(container: container)

        #expect(relaunched.isWatched(showID: 1399, season: 1, episode: 2))
        #expect(relaunched.upNext.first?.show.name == "Game of Thrones")
    }

    @Test func stopTrackingRemovesEverything() {
        let tracker = EpisodeTracker()
        tracker.toggle(episode(1, 1), show: show, seasons: seasons)

        tracker.stopTracking(showID: 1399)

        #expect(tracker.upNext.isEmpty)
        #expect(tracker.watchedKeys.isEmpty)
    }

    @Test func nextEpisodeWithNothingWatchedIsTheFirstOne() {
        let counts = [SeasonCount(season: 1, episodes: 3)]
        #expect(EpisodeTracker.nextEpisode(after: [], showID: 1, counts: counts)! == (1, 1))
    }
}

struct EpisodeModelTests {
    @Test func airDateParsingAndHasAired() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14
        #expect(episode(1, 1, airDate: "2023-11-14").hasAired(asOf: now))
        #expect(!episode(1, 1, airDate: "2023-11-15").hasAired(asOf: now))
        #expect(!episode(1, 1, airDate: nil).hasAired(asOf: now))
        #expect(!episode(1, 1, airDate: "soon").hasAired(asOf: now))
    }

    @Test func seasonDecodesSortedEpisodes() async throws {
        let json = Data(
            """
            { "season_number": 1, "name": "Season 1", "episodes": [
              { "id": 2, "season_number": 1, "episode_number": 2, "name": "B", "air_date": "2011-04-24", "still_path": null, "runtime": 56 },
              { "id": 1, "season_number": 1, "episode_number": 1, "name": "", "air_date": "", "still_path": "/a.jpg", "runtime": null }
            ] }
            """.utf8)
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (json, 200) }, language: "en-US")

        let season = try await client.season(1, ofShow: 1399)

        #expect(season.episodes.map(\.number) == [1, 2])
        #expect(season.episodes[0].name == "Episode 1")  // empty name falls back
        #expect(season.episodes[0].airDate == nil)
    }

    @Test func detailsDecodeTheNextEpisode() async throws {
        var object = try JSONSerialization.jsonObject(with: Fixtures.tvDetailsJSON) as! [String: Any]
        object["next_episode_to_air"] = [
            "id": 9, "season_number": 9, "episode_number": 1, "name": "Return", "air_date": "2030-05-01",
        ]
        let json = try JSONSerialization.data(withJSONObject: object)
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (json, 200) })

        let details = try await client.details(for: TitleID(mediaType: .tv, tmdbID: 1399))

        #expect(details.nextEpisode?.name == "Return")
        #expect(details.nextEpisode?.seasonNumber == 9)
    }

    @Test func requestsUseTheUsersLanguage() async throws {
        let http = StubHTTPClient { _ in (Fixtures.trendingJSON, 200) }
        _ = try await TMDBClient(token: "t", http: http, language: "pt-BR").trending(.day, page: 1)

        #expect(http.lastRequest?.url?.query()?.contains("language=pt-BR") == true)
        #expect(TMDBClient.preferredLanguage(["pt-PT", "en"]) == "pt-BR")
        #expect(TMDBClient.preferredLanguage(["es-AR"]) == "en-US")
    }
}

struct RouterTests {
    @Test func parsesTitleLinks() {
        #expect(Router.titleID(from: URL(string: "timeskip://title/tv/1399")!) == TitleID(mediaType: .tv, tmdbID: 1399))
        #expect(Router.titleID(from: URL(string: "timeskip://title/movie/27205")!)?.mediaType == .movie)
    }

    @Test(arguments: [
        "https://title/tv/1399", "timeskip://person/1", "timeskip://title/book/1", "timeskip://title/tv/abc",
        "timeskip://title/tv", "timeskip://title/tv/-1",
    ])
    func rejectsUnknownLinks(_ link: String) {
        #expect(Router.titleID(from: URL(string: link)!) == nil)
    }

    @Test func openingALinkGoesHomeAndPushesTheTitle() {
        let router = Router()
        router.selectedTab = .search

        #expect(router.open(Router.url(for: TitleID(mediaType: .tv, tmdbID: 1399))))
        #expect(router.selectedTab == .home)
        #expect(router.homePath.count == 1)
        #expect(!router.open(URL(string: "timeskip://nope")!))
    }
}

/// Records what would be sent to `UNUserNotificationCenter`.
final class FakeNotificationCenter: NotificationScheduling {
    var granted = true
    private(set) var added: [UNNotificationRequest] = []
    private(set) var removed: [String] = []

    func requestAuthorization() async -> Bool { granted }
    func add(_ request: UNNotificationRequest) async throws { added.append(request) }
    func removePending(identifiers: [String]) { removed += identifiers }
    func pendingIdentifiers() async -> [String] { added.map(\.identifier).filter { !removed.contains($0) } }
}

struct EpisodeRemindersTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14

    @Test func schedulesAtNineOnTheAirDateWithADeepLink() async throws {
        let center = FakeNotificationCenter()
        let reminders = EpisodeReminders(center: center)

        let outcome = await reminders.toggle(show: show, next: episode(8, 1, airDate: "2023-12-01"), now: now)

        #expect(outcome == .scheduled)
        #expect(reminders.isScheduled(showID: 1399))
        let request = try #require(center.added.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.day == 1)
        #expect(trigger.dateComponents.hour == 9)
        #expect(request.content.userInfo["url"] as? String == "timeskip://title/tv/1399")
    }

    @Test func secondTapCancels() async {
        let center = FakeNotificationCenter()
        let reminders = EpisodeReminders(center: center)
        let next = episode(8, 1, airDate: "2023-12-01")

        await reminders.toggle(show: show, next: next, now: now)
        let outcome = await reminders.toggle(show: show, next: next, now: now)

        #expect(outcome == .cancelled)
        #expect(center.removed == [EpisodeReminders.identifier(for: 1399)])
        #expect(!reminders.isScheduled(showID: 1399))
    }

    @Test func deniedPermissionSchedulesNothing() async {
        let center = FakeNotificationCenter()
        center.granted = false
        let reminders = EpisodeReminders(center: center)

        let outcome = await reminders.toggle(show: show, next: episode(8, 1, airDate: "2023-12-01"), now: now)

        #expect(outcome == .denied)
        #expect(center.added.isEmpty)
    }

    @Test func pastEpisodesAreNotScheduled() async {
        let reminders = EpisodeReminders(center: FakeNotificationCenter())
        #expect(
            await reminders.toggle(show: show, next: episode(1, 1, airDate: "2023-01-01"), now: now) == .alreadyAired)
    }

    @Test func refreshReadsPendingReminders() async {
        let center = FakeNotificationCenter()
        await EpisodeReminders(center: center).toggle(show: show, next: episode(8, 1, airDate: "2023-12-01"), now: now)

        let fresh = EpisodeReminders(center: center)
        await fresh.refresh()

        #expect(fresh.isScheduled(showID: 1399))
        #expect(EpisodeReminders.showID(fromIdentifier: "something-else") == nil)
    }
}

struct SeasonViewModelTests {
    @Test func loadsEpisodes() async {
        let service = MockTMDBService()
        await service.setSeason(.success(SeasonDetails(showID: 1399, number: 1, name: "S1", episodes: [episode(1, 1)])))
        let model = SeasonViewModel(show: show, season: seasons[1], allSeasons: seasons, service: service)

        await model.load()

        #expect(model.episodes.count == 1)
    }

    @Test func failureShowsError() async {
        let service = MockTMDBService()
        await service.setSeason(.failure(.offline))
        let model = SeasonViewModel(show: show, season: seasons[1], allSeasons: seasons, service: service)

        await model.load()

        #expect(model.state == .failed(.offline))
    }
}
