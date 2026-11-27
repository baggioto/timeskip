# 0010: "Up next" widget through an app-group snapshot

- Status: Accepted
- Date: 2026-11-27

## Context
A home-screen widget that shows the next episode to watch. The widget runs in its own process, so it can't read the app's memory, and the SwiftData store lives in the app's sandbox. The roadmap assumed this needed the paid developer account; Apple's capability table lists App Groups for free Apple Developer accounts too, so it doesn't.

## Decision
- App and widget share the app group `group.com.baggioto.Timeskip`.
- The app writes a small JSON **snapshot** of "Up next" (`up-next.json`) to the group container whenever the list changes, then calls `WidgetCenter.reloadTimelines(ofKind:)`. The widget only reads that file.
- The SwiftData store **stays in the app's sandbox**. The widget doesn't open it.
- The snapshot type and its store live in a Foundation-only package module, `AppGroupKit`, used by both targets.
- `EpisodeTracker` publishes through an `UpNextPublishing` protocol, so tests check what gets published without an app group or WidgetKit.
- The timeline policy is `.never`: the app is the only thing that changes "Up next", and it reloads the widget itself. The provider downloads poster thumbnails before building the entry, since widget views can't load images while drawing.
- Small, medium and lock-screen (`accessoryRectangular`) sizes. Taps open the show through the existing `timeskip://title/tv/{id}` deep link (a test keeps the widget's link in sync with `Router`).

## Consequences
- No shared database means no migration of the existing store, no SwiftData models in the extension, and no two processes writing to one store.
- The widget is only as fresh as the app's last change. That's exact for "Up next", which only changes when the user marks episodes in the app.
- In CI, builds run with code signing off, so the group container is `nil`. The snapshot store then does nothing, and the app works as before.
- A real device needs signing with a team (a free personal team works, with 7-day provisioning).
