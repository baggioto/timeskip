# 0009: Episode tracking and new-episode reminders, all on device

- Status: Accepted
- Date: 2026-11-26

## Context
v0.3 adds "which episode am I on?" (the problem in PRODUCT.md) and a heads-up when a new episode airs. The app has no backend and no accounts, on purpose.

## Decision
- **Watched episodes** are SwiftData rows (`WatchedEpisode`, unique key `showID-sSeE`), in the same store as the watchlist.
- **Tracked shows** (`TrackedShow`) keep a snapshot of the show plus the episode count per season, so **"Up next" is computed locally**: the first unwatched episode after the furthest one watched. Specials (season 0) don't count. No TMDB call is needed to render the Watchlist tab.
- **Reminders are local notifications**, scheduled for 9:00 on the air date from TMDB's `next_episode_to_air`, when the user taps the bell on a show. The notification carries a `timeskip://title/tv/{id}` link, and a tap goes through the same deep-link router as any URL.
- `UNUserNotificationCenter` sits behind a small `NotificationScheduling` protocol so scheduling, cancelling and permission denial are unit-tested.

## Consequences
- Works offline and needs no server, push certificates or accounts.
- A reminder uses the air date known when it was set. If TMDB moves the date, the reminder is wrong until the user opens the show again. A background refresh (BGAppRefreshTask) would fix this and is a natural next step.
- "Up next" assumes episodes are watched in order; marking a later episode moves "Up next" past the gaps. That matches how people binge, and the season screen still shows every unwatched episode.
