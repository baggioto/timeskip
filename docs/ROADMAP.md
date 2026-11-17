# Roadmap

Each milestone is small enough to finish. A box is only checked when it's merged, tested and documented.

## v0.0: Foundations
- [x] Name, scope and docs (2026-11-17)
- [ ] Screen mockups
- [ ] Xcode project, folder structure, Swift 6 strict concurrency on
- [ ] Secrets handling for the TMDB token (ADR 0004)
- [ ] GitHub Actions: build + test on every push

## v0.1: MVP
- [ ] API client (`async`/`await`, typed errors)
- [ ] Trending feed with pagination
- [ ] Actor-based image cache (memory + disk)
- [ ] Details screen
- [ ] Search with debounce + cancellation
- [ ] Watchlist (in memory)
- [ ] Loading / empty / error states
- [ ] Unit tests for ViewModels with a mocked API

## v0.2: Persistence & architecture
- [ ] SwiftData watchlist + watched episodes
- [ ] Offline cache of the last feed
- [ ] Split into SPM modules (Networking, DesignSystem, Features)
- [ ] Dependency injection through init/protocols
- [ ] Snapshot tests + a few UI tests
- [ ] Lint (SwiftLint or swift-format) in CI

## v0.3: Quality & platform
- [ ] Episode tracking + "up next"
- [ ] Accessibility: VoiceOver, Dynamic Type
- [ ] EN / PT localization
- [ ] Performance pass with Instruments (before/after numbers in docs)
- [ ] Widget ("up next")
- [ ] Deep links
- [ ] Local notifications for new episodes
- [ ] Logging (OSLog) + MetricKit

## v1.0: Ship
- [ ] Fastlane + TestFlight
- [ ] README with GIFs and an architecture diagram
- [ ] Design doc in `docs/`
