# 0003: SwiftUI and Swift 6 strict concurrency

- Status: Accepted
- Date: 2026-11-17

## Context
Modern iOS roles expect SwiftUI and Swift Concurrency. A new project has no legacy code to migrate, so it can start with the strictest settings.

## Decision
- UI in SwiftUI with the Observation framework (`@Observable`).
- Swift 6 language mode with strict concurrency checking from day one.
- `async`/`await` for all asynchronous work, actors for shared mutable state (e.g. the image cache).

## Consequences
- Data races are caught at compile time instead of in production.
- Some APIs need explicit `Sendable`/`@MainActor` annotations; that friction is part of what the project practices.
- UIKit only where SwiftUI has no equivalent, wrapped with `UIViewRepresentable`.
