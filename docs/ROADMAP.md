# Roadmap

Each milestone is small enough to finish. A box is only checked when it's merged, tested and documented.

## v0.0: Foundations
- [x] Name, scope and docs (2026-11-17)
- [x] Screen mockups in [Figma](https://www.figma.com/design/XDV0KDQZaAJM0Gkda3pgAT) (2026-11-17)
- [x] Xcode project (XcodeGen), folder structure, Swift 6 strict concurrency on (2026-11-17)
- [x] Secrets handling for the TMDB token (ADR 0004) (2026-11-17)
- [x] GitHub Actions: build + test on every push (2026-11-17)

## v0.1: MVP
- [x] API client (`async`/`await`, typed errors) (2026-11-26)
- [x] Trending feed with pagination (2026-11-26)
- [x] Actor-based image cache (memory + disk) (2026-11-26)
- [x] Details screen (2026-11-26)
- [x] Search with debounce + cancellation (2026-11-26)
- [x] Watchlist (in memory) (2026-11-26)
- [x] Loading / empty / error states (2026-11-26)
- [x] Unit tests for ViewModels with a mocked API (2026-11-26)

## v0.2: Persistence & architecture
- [x] SwiftData watchlist (2026-11-26). Watched episodes moved to v0.3, together with episode tracking
- [x] Offline cache of the last feed (2026-11-26)
- [x] Split into SPM modules: `TMDBKit` and `DesignSystem`; features stay in the app for now ([ADR 0007](adr/0007-spm-modules.md)) (2026-11-26)
- [x] Dependency injection through init/protocols (2026-11-26)
- [x] UI tests for the main flows (2026-11-26)
- [ ] Snapshot tests: postponed until CI runs on a pinned simulator, since reference images differ between simulator versions
- [x] Lint: swift-format (ships with Xcode) in CI (2026-11-26)

## v0.3: Quality & platform
- [x] Episode tracking + "Up next", watched episodes in SwiftData ([ADR 0009](adr/0009-episode-tracking-and-reminders.md)) (2026-11-26)
- [x] Accessibility, first pass: VoiceOver labels and actions on cards, rows and episodes; Dynamic Type-scaled grid and thumbnails (2026-11-26)
- [ ] Accessibility Inspector audit on a device, plus larger text sizes in UI tests
- [x] EN / PT-BR localization: String Catalogs in the app and both packages; TMDB data in the user's language (2026-11-26)
- [x] Performance tests with XCTest metrics, simulator numbers in [PERFORMANCE.md](PERFORMANCE.md)
- [x] iPad and landscape: adaptive grid, sidebar-adaptable tabs, readable-width details, a landscape UI test
- [ ] Performance pass with Instruments on a device (hitch ratio, real launch time)
- [ ] Widget ("Up next"): needs an App Group, so it waits for the paid developer account and signing setup
- [x] Deep links: `timeskip://title/{movie|tv}/{id}` (2026-11-26)
- [x] Local notifications on the day the next episode airs (2026-11-26)
- [x] Logging (OSLog categories) + MetricKit subscriber (2026-11-26)

## v1.0: Ship
- [ ] Fastlane + TestFlight
- [x] README with GIFs and an architecture diagram (2026-11-26)
- [ ] Design doc in `docs/`
