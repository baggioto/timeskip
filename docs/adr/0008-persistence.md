# 0008: SwiftData for the watchlist, JSON files for the feed cache

- Status: Accepted
- Date: 2026-11-26

## Context
v0.1 kept the watchlist in memory. v0.2 needs it to survive relaunches, and the trending grid should show something when the app opens offline.

## Decision
- **Watchlist: SwiftData.** A `WatchlistEntry` model stores a snapshot of what the rows need (name, poster path, rating, date added), unique by `TitleID` ("movie-27205"). Views never touch SwiftData: they use `WatchlistStore`, whose API didn't change from v0.1.
- **Feed cache: JSON files in Caches.** The last first page of each trending window (`Title` is `Codable`). On launch the grid shows the saved page right away with an "Updating…" notice, then replaces it with the fresh response. Offline, it stays with "Offline · saved 2 hours ago".

## Consequences
- The watchlist works fully offline and could move to CloudKit later by changing only the store.
- The feed cache is disposable by definition (the system can purge Caches), so it doesn't get a schema or migrations.
- If the SwiftData store fails to open, the app logs it and falls back to memory instead of crashing.
- UI tests and the unit-test host never touch the real store (in-memory container, canned data).
