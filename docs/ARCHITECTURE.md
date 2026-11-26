# Architecture

Timeskip is a SwiftUI app with MVVM per feature, a composition root that wires dependencies, and shared code in a local Swift package. There is no backend: TMDB is the only remote service, and everything the user owns (watchlist, watched episodes, reminders) lives on the device.

## Modules and layers

```mermaid
flowchart TB
    subgraph App["Timeskip (app target)"]
        direction TB
        Root["TimeskipApp + AppDelegate<br/>AppDependencies (composition root)<br/>Router (tabs, deep links)"]
        subgraph Features
            direction LR
            Trending["Trending<br/>View + ViewModel"]
            Details["Details<br/>View + ViewModel"]
            Episodes["Season / Episodes<br/>View + ViewModel"]
            Search["Search<br/>View + ViewModel"]
            Watchlist["Watchlist + Up next<br/>View"]
        end
        subgraph Stores["App state (@Observable)"]
            direction LR
            WS["WatchlistStore"]
            ET["EpisodeTracker"]
            ER["EpisodeReminders"]
            FC["FeedCache"]
            RS["RecentSearchesStore"]
        end
    end

    subgraph Kit["Packages/TimeskipKit"]
        direction LR
        DS["DesignSystem<br/>Theme, PosterCard, TitleRow,<br/>RemoteImage, ErrorStateView"]
        TK["TMDBKit<br/>Models, TMDBService, TMDBClient,<br/>DTOs, APIError, ImageCache, Log"]
    end

    subgraph System["Apple frameworks / outside world"]
        direction LR
        SD[("SwiftData store")]
        Caches[("Caches: feed JSON,<br/>poster files")]
        UN["UserNotifications"]
        TMDB(["TMDB API"])
    end

    Root --> Features
    Root --> Stores
    Features --> Stores
    Features --> DS
    Features --> TK
    DS --> TK
    WS --> SD
    ET --> SD
    FC --> Caches
    ER --> UN
    TK -- "async/await, URLSession" --> TMDB
    TK --> Caches
```

- **Features** depend on protocols (`TMDBService`, `FeedCaching`, `NotificationScheduling`) handed in by `AppDependencies`, so tests and previews swap in fakes.
- **DesignSystem** knows TMDB models but never app state: a poster card is told `isSaved`, it doesn't read the watchlist ([ADR 0007](adr/0007-spm-modules.md)).
- **Views never touch SwiftData.** They talk to `WatchlistStore` and `EpisodeTracker`, which own a `ModelContext` each on one shared store ([ADR 0008](adr/0008-persistence.md)).

## Loading the trending feed

```mermaid
sequenceDiagram
    participant V as TrendingView
    participant VM as TrendingViewModel
    participant C as FeedCache
    participant S as TMDBService
    participant API as TMDB

    V->>VM: .task { loadIfNeeded() }
    VM->>C: load(.day)
    alt saved page exists
        C-->>VM: CachedFeed
        VM-->>V: items + "Updating…"
    else nothing saved
        VM-->>V: spinner
    end
    VM->>S: trending(.day, page: 1)
    S->>API: GET /trending/all/day
    alt success
        API-->>S: JSON
        S-->>VM: Page<Title> (decoded off the main actor)
        VM->>C: save(items)
        VM-->>V: fresh grid
    else offline
        S-->>VM: throws APIError.offline
        VM-->>V: saved grid + "Offline · saved 2 hours ago"<br/>(or full-screen error if nothing saved)
    end
```

## Concurrency

- Swift 6 language mode with **`MainActor` as the default isolation**: views, ViewModels and stores run on the main actor without annotations.
- **Background work is explicit:** JSON decoding and image decoding are `@concurrent`; `ImageCache` is an `actor` that dedupes concurrent downloads ([ADR 0006](adr/0006-actor-image-cache.md)); model types are `nonisolated` and `Sendable`.
- **Cancellation is structured:** search runs its debounce and request in one `Task`, cancelled on the next keystroke; `.task(id:)` cancels image loads for cells that scroll away.

## Deep links and notifications

`timeskip://title/{movie|tv}/{id}` → `Router.open(_:)` selects the Home tab and pushes the title. A tapped reminder carries the same URL in `userInfo`, and `AppDelegate` opens it, so both entry points share one code path ([ADR 0009](adr/0009-episode-tracking-and-reminders.md)).
