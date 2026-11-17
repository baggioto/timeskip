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
