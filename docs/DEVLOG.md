# Dev log

One entry per work session: what was done, what was decided, what's next.

## 2026-11-17: Kickoff
- Picked the project: a movie & TV tracker built on the TMDB API, from scratch.
- Name: **Timeskip**.
- Wrote the product scope ([PRODUCT.md](PRODUCT.md)), the [roadmap](ROADMAP.md) and the first ADRs.
- Mockups in [Figma](https://www.figma.com/design/XDV0KDQZaAJM0Gkda3pgAT): 6 screens (Trending, Details, Search, Watchlist, empty watchlist, offline error), 10 color variables (dark theme, amber accent) and 5 base components (PosterCard, ListRow, TabBar, Button/Primary, Chip). Posters are placeholders for TMDB artwork.
- Next: create the Xcode project (Swift 6, strict concurrency) and the secrets setup from ADR 0004.
