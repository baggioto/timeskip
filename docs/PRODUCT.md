# Product

## Problem
Keeping track of what to watch is scattered: recommendations in chats, half-watched series, "what episode was I on?". Timeskip keeps it in one place.

## Users
- People who follow several series at once and lose track of episodes.
- People who collect movie/series recommendations and forget them.

## MVP v0.1 scope
| # | Screen | What it does |
|---|--------|--------------|
| 1 | **Home / Trending** | Trending movies & shows (day/week), poster grid, infinite scroll, pull to refresh |
| 2 | **Details** | Backdrop, poster, title, year, rating, genres, overview, cast, seasons (shows), add to watchlist |
| 3 | **Search** | Search as you type (debounced, previous request cancelled), recent searches |
| 4 | **Watchlist** | Saved titles, remove, empty state |
| 5 | **About** | Credits, TMDB logo and notice |

Every screen has loading, empty and error states.

## Out of scope (on purpose)
- Accounts, login, a backend, or sync between devices
- Streaming/playback
- Social features (reviews, friends)

These keep the project finishable. They may come back later as design exercises in `docs/`.

## Later (after MVP)
Episode tracking ("up next"), offline cache, widgets, local notifications for new episodes, deep links, EN/PT localization, accessibility pass. See [ROADMAP.md](ROADMAP.md).
