# 0007: Shared code in SPM modules, features in the app target

- Status: Accepted
- Date: 2026-11-26

## Context
After v0.1 everything lived in one app target. Splitting into modules gives faster incremental builds, enforced boundaries (a module can only see what another makes `public`) and code that can be tested or reused on its own. But every module also costs: `public` API, explicit inits, and more project setup. The app has five screens.

## Decision
One local package, `Packages/TimeskipKit`, with two libraries:
- **`TMDBKit`:** models, the TMDB client, DTOs, errors and the image cache. No SwiftUI.
- **`DesignSystem`:** color tokens and reusable views (`PosterCard`, `TitleRow`, `RemoteImage`, `ErrorStateView`…). Depends on `TMDBKit`, never on features.

Features (Trending, Details, Search, Watchlist, About), their ViewModels, persistence and the composition root stay in the app target.

## Consequences
- The boundaries that matter are enforced: views can't reach into DTOs or `Endpoint`, and design components can't depend on app state (e.g. `PosterCard` takes `isSaved: Bool` instead of reading the watchlist).
- Feature modules are deferred on purpose: with five small screens they would add more `public` boilerplate than they save. Revisit when a feature grows its own models or when build times justify it.
- Tests use `@testable import TMDBKit`, so internal types (`Endpoint`, DTOs) stay internal.
