# 0006: A custom actor-based image cache instead of AsyncImage

- Status: Accepted
- Date: 2026-11-26

## Context
Every screen shows TMDB posters, and the trending grid can show hundreds of them. `AsyncImage` keeps nothing between loads: when a cell scrolls off and back, or the same poster appears in Trending, Search and the Watchlist, it downloads again. It also decodes the JPEG on the main thread the first time it's drawn, which costs frames while scrolling. Third-party libraries (Kingfisher, Nuke) solve this, but the project wants no dependencies for something this central and wants the concurrency design to be visible.

## Decision
`ImageCache` is an **actor** with two levels:
- **Memory:** a dictionary bounded by count with least-recently-used eviction.
- **Disk:** files in the Caches directory, named by the SHA-256 of the URL (the system may purge them).
- **In-flight dedupe:** a `[URL: Task<UIImage, Error>]` map, so concurrent requests for the same URL await one download.
- Disk reads, downloads and decoding (`byPreparingForDisplay()`) run in a `@concurrent` function, off the actor, so the actor only guards state and keeps answering cache hits.

`RemoteImage` (SwiftUI) loads through it in `.task(id:)`, so a cell that scrolls away cancels its request.

## Consequences
- Posters load once per session, survive relaunches on disk, and scrolling doesn't decode on the main thread.
- The actor removes the need for locks; reentrancy is handled by checking `inFlight` before starting work.
- The download function is injected, so dedupe, eviction and the disk level are unit-tested without the network.
- Not covered yet: memory-warning purge and disk size limits (planned for the v0.3 performance pass).
