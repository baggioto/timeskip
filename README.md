# Timeskip

A movie & TV tracker for iOS: browse what's trending, search, keep a watchlist and track the episodes you've watched.

Built in public as a senior-level iOS portfolio project: every feature is a deliberate exercise in modern iOS engineering (SwiftUI, Swift Concurrency, testing, modularization, CI) and every decision is documented.

> **Status:** planning. No app code yet. See the [roadmap](docs/ROADMAP.md) and the [dev log](docs/DEVLOG.md).

## Planned features (MVP v0.1)
- Trending movies & shows with infinite scroll
- Title details (overview, cast, seasons)
- Search with debounce and cancellation
- Watchlist

Later: offline support, episode tracking, widgets, notifications, deep links. Full plan in [docs/ROADMAP.md](docs/ROADMAP.md).

## Tech stack
| Area | Choice |
|------|--------|
| UI | SwiftUI, `@Observable`, `NavigationStack` |
| Language | Swift 6, strict concurrency |
| Networking | `async`/`await` with `URLSession` |
| Images | Custom actor-based cache (memory + disk) |
| Persistence | SwiftData (planned) |
| Modules | Swift Package Manager (planned) |
| Tests | Swift Testing, snapshot tests (planned) |
| CI | GitHub Actions (planned) |
| Data | [TMDB API](https://developer.themoviedb.org/) |

Minimum target: iOS 18 (to be confirmed in an ADR when the project is created).

## Documentation
| Doc | What's in it |
|-----|--------------|
| [docs/PRODUCT.md](docs/PRODUCT.md) | Problem, users, MVP scope, screens, what's out of scope |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Milestones and the engineering checklist |
| [docs/DEVLOG.md](docs/DEVLOG.md) | Dated log of every work session |
| [docs/adr/](docs/adr/) | Architecture Decision Records |
| [Figma: MVP v0.1 screens](https://www.figma.com/design/XDV0KDQZaAJM0Gkda3pgAT) | Screen mockups, color variables and base components |

## Getting started
Coming with v0.1. You'll need a free TMDB API read access token in a local `Secrets.xcconfig` (never committed).

## Attribution
<!-- TMDB requires this notice and their logo in the app's About screen -->
This product uses the TMDB API but is not endorsed or certified by TMDB.
