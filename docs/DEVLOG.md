# Dev log

One entry per work session: what was done, what was decided, what's next.

## 2026-11-17: Kickoff
- Picked the project: a movie & TV tracker built on the TMDB API, from scratch.
- Name: **Timeskip**.
- Wrote the product scope ([PRODUCT.md](PRODUCT.md)), the [roadmap](ROADMAP.md) and the first ADRs.
- Mockups in [Figma](https://www.figma.com/design/XDV0KDQZaAJM0Gkda3pgAT): 6 screens (Trending, Details, Search, Watchlist, empty watchlist, offline error), 10 color variables (dark theme, amber accent) and 5 base components (PosterCard, ListRow, TabBar, Button/Primary, Chip). Posters are placeholders for TMDB artwork.
- Created the Xcode project with XcodeGen (iOS 18, Swift 6, MainActor by default): tab shell (Home / Search / Watchlist) with placeholder screens, color tokens mirrored from the Figma variables, TMDB token read from a git-ignored xcconfig via Info.plist, and a first Swift Testing suite (2 tests, green). ADR 0005 records the iOS 18 + XcodeGen decision.
- Repo published: github.com/baggioto/timeskip.
- Added GitHub Actions CI: generates the project with XcodeGen and runs the unit tests on every push and PR (no secrets needed).
- Next: the TMDB API client (first v0.1 feature).

## 2026-11-26: v0.1 MVP
- TMDB client: `async throws(APIError)`, endpoints as an enum, DTOs that merge the movie/show key differences into one `Title`, decoding off the main actor (`@concurrent`), transport behind an `HTTPClient` protocol for tests.
- Titles are identified by `(mediaType, id)` because TMDB movie and show ids overlap.
- Trending: today/this week, infinite scroll with prefetch, pull to refresh, duplicate filtering across pages, a generation counter to drop stale responses.
- Image cache: actor with memory LRU + disk, shared in-flight downloads, decoding in the background ([ADR 0006](adr/0006-actor-image-cache.md)).
- Details: backdrop header, genres, runtime, overview, cast, seasons (Specials last), add/remove from the watchlist.
- Search: debounce + cancellation in one `Task`, recent searches in `UserDefaults`.
- Watchlist (in memory), About screen with the TMDB notice.
- Composition root (`AppDependencies`) injects the service; with no token the app shows a clear error instead of crashing.
- 38 Swift Testing tests. They caught two bugs before they shipped: a test that depended on the device locale, and a search that could stay on the spinner forever after an unexpected cancellation.
- Next: v0.2, SwiftData for the watchlist, offline cache of the last feed, SPM modules.

## 2026-11-26: v0.2 Persistence & architecture
- Watchlist persisted with SwiftData behind the same `WatchlistStore` API ([ADR 0008](adr/0008-persistence.md)).
- Offline: the last trending page per window is cached as JSON; the grid shows it immediately and explains why ("Updating…", "Offline · saved 2 hours ago").
- Shared code moved to a local package with `TMDBKit` and `DesignSystem` ([ADR 0007](adr/0007-spm-modules.md)). Design components no longer read app state.
- UI tests (XCUITest) for add-to-watchlist, search and the About screen, running on canned data via `-ui-testing`.
- swift-format config + a lint job in CI; CI now runs unit and UI tests.
- Found while testing: the unit-test host app was opening the real SwiftData store before Application Support existed. The folder is now created up front, and the test host uses in-memory dependencies.
- 46 unit tests + 3 UI tests.
- Postponed: snapshot tests (reference images depend on the simulator version), watched episodes (moved to v0.3 with episode tracking).

## 2026-11-26: v0.3 Episodes, reminders, deep links, EN/PT
- Episode tracking: season screen with tap-to-watch rows and "Mark all watched" (aired episodes only); progress bars per season; "Up next" section in the Watchlist tab, computed on device ([ADR 0009](adr/0009-episode-tracking-and-reminders.md)).
- Next episode card on show details, with a bell that schedules a local notification for the air date.
- Deep links (`timeskip://title/tv/1399`) through a `Router` that owns the tab selection and the Home navigation path; notification taps reuse it.
- Navigation destinations registered once (`appDestinations`) for all three tabs.
- OSLog categories (network timing, persistence, notifications, metrics) and a MetricKit subscriber.
- Localization: String Catalogs for the app, `TMDBKit` and `DesignSystem` (pt-BR, with plural rules); TMDB requests use pt-BR for Portuguese-speaking users, so titles, overviews and posters come back in Portuguese.
- Accessibility first pass: combined VoiceOver elements with values ("Watched"), a VoiceOver action to save a title straight from the grid, and Dynamic Type-scaled grid cells and thumbnails.
- Found by the new UI test: tapping an episode row missed the small checkmark button. The whole row is now the tap target.
- 67 unit tests + 4 UI tests.
- Not done, on purpose: the widget (needs an App Group, so signing with a paid account) and the Instruments pass (needs real profiling on a device, with measured numbers).

## 2026-11-26: README media and architecture docs
- Two GIFs recorded from the simulator while a UI test (`DemoRecordingTests`, skipped unless `TIMESKIP_DEMO=1`) drives the real app with live data: browse → details → watchlist, and search → season → mark episodes → Up next. Steps in [media/README.md](media/README.md).
- [ARCHITECTURE.md](ARCHITECTURE.md): module/layer diagram, feed-loading sequence diagram, concurrency model and deep links (Mermaid, rendered by GitHub). A compact version is in the README.
- Fixed text cut off at the screen edges on the details screen: `RemoteImage` used a `ZStack`, so a `scaledToFill` backdrop grew the layout wider than the screen. The image now sits in an overlay on a color that takes exactly the offered size. GIFs re-recorded.


## 2026-11-27: Performance numbers
- XCTest performance tests: launch time (`XCTApplicationLaunchMetric`), scrolling a 200-title Trending grid (`scrollDecelerationMetric` + `XCTMemoryMetric`), and the image cache per level (`XCTClockMetric`). Results in [PERFORMANCE.md](PERFORMANCE.md), rerun with `scripts/perf.sh`.
- Simulator, Debug build: memory hit ~17 µs per poster, disk hit ~7.6 ms, miss without network ~9.2 ms; launch to responsive 1.49 s; 64 MB peak while scrolling, with no growth between flings.
- `PreviewTMDBService(feedPages:)` serves a long paginated feed for the scroll test (`-ui-testing-large-feed`).
- The UI performance tests only run with `TEST_RUNNER_TIMESKIP_PERF=1`, because CI runners are too noisy. The simulator doesn't report hitch ratio; that needs the device pass.

## 2026-11-27: iPad and landscape
- The app now runs on iPad (all orientations) and on iPhone in landscape.
- Tabs use `.sidebarAdaptable`: a tab bar on iPhone, a floating tab bar on iPad that turns into a sidebar.
- Trending grid: bigger minimum cell width in regular width, so iPad shows 6 large posters per row instead of a dozen small ones.
- Details: content capped at a 720 pt readable width and centered (the backdrop stays full width); a taller backdrop on iPad and a shorter header in compact height, so on a landscape iPhone the title and "Add to Watchlist" fit on the first screen.
- New UI test: rotates to landscape, opens a title and checks the title and the watchlist button are hittable. All 5 UI tests pass on iPhone 17 Pro and iPad Pro 13".
- On iPad the floating tab bar isn't exposed to XCUITest as a `TabBar`, so the tests find tabs through a small helper.

## 2026-11-27: "Up next" widget
- Checked the assumption in the roadmap: App Groups are available to free Apple Developer accounts, so the widget didn't need to wait for the paid account.
- The app writes a JSON snapshot of "Up next" to the app group and reloads the widget; the widget never opens the SwiftData store ([ADR 0010](adr/0010-up-next-widget.md)). Shared code in a new Foundation-only module, `AppGroupKit`.
- Small (poster, show, next episode, progress), medium (top 3 shows, each tappable) and lock-screen sizes; taps open the show through the existing deep link. Strings in English and Portuguese.
- Verified on the simulator: the snapshot lands in the group container, and the widget on the home screen shows the real poster and next episode.
- 4 new unit tests (71 total): publishing on change, the store round trip, no app group in CI, and the widget link matching `Router`.

## 2026-11-27: Device performance pass, and a Release build fix
- The app didn't compile in Release: `PreviewTMDBService` is `#if DEBUG`, but the `#Preview` blocks and the UI-testing path in `AppDependencies` used it unguarded. CI only built Debug, so it never showed up. Wrapped those call sites in `#if DEBUG` (Release ships no canned data) and added a Release build job to CI.
- Ran the performance UI tests on an iPhone 13 (iOS 27.2.1): 0 hitches in 5 flings through 200 titles at ~58.6 fps, 32.6 MB peak memory, launch to responsive 0.95 s (Debug).
- Instruments App Launch on a Release build: ~0.67 s from tap to first frame once caches are warm. The app's own startup code takes ~13 ms; the rest is process creation and the first SwiftUI render. Details in [PERFORMANCE.md](PERFORMANCE.md).
- Correction to the widget entry: with a free account, Xcode's automatic signing didn't add the App Group to the provisioning profile from the command line, so the device builds for this pass were signed without it (the snapshot is skipped safely when the container is `nil`). The widget is verified on the simulator only; checking it on a device is open.

## 2026-11-27: Design doc
- New [DESIGN.md](DESIGN.md): the end-to-end document to read first. Goals and non-goals, functional and non-functional requirements (with the measured device numbers next to each target), data and endpoints, key flows, concurrency, alternatives considered, failure modes, security and privacy, observability, testing, risks and a release plan. It links to ARCHITECTURE.md and the ADRs instead of repeating them.
- Writing it surfaced two honest limitations, now listed: a reminder isn't rescheduled if TMDB moves the air date, and the TMDB read token ships inside the app binary (fine for a read-only public token; a commercial app would proxy it).

