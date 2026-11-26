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

