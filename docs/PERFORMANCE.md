# Performance

Measured with XCTest metrics (`measure(metrics:)`), so anyone can rerun them: `scripts/perf.sh`.

Two sets of numbers: a **real device** (iPhone 13, iOS 27.2.1), and the **simulator** (iPhone 17 Pro simulator, Debug build, on a Mac). Use the device numbers to judge the app; use the simulator ones to compare changes over time, since a simulator runs on the Mac's CPU and disk.

Last run: 2026-11-27, v0.3.

## On a device (iPhone 13)
An iPhone 13 is a 2021 phone with a 60 Hz screen, a fair "average user" device rather than a current Pro.

### Scrolling Trending
Same test as below (fast fling through 200 titles, 5 iterations), Debug build with canned data.

| Metric | Average |
|--------|--------:|
| Hitches | **0** in all 5 flings (hitch time ratio 0 ms/s) |
| Frame rate | **58.6 fps** (screen max 60) |
| Peak memory | **32.6 MB** |
| Memory change per fling | **~0.2 MB** (no real growth) |

### Launch
| Metric | Result |
|--------|-------:|
| Launch until the app responds (XCTest, Debug, 5 runs) | **0.95 s** |
| Release build, tap to first frame (Instruments App Launch, warm, 2 runs) | **~0.67 s** |

Where the Release launch goes (Instruments, App Launch template, runs 3–4 after install):

| Phase | Time |
|-------|-----:|
| Process creation + dyld (system) | ~390 ms |
| UIKit initialization | ~45 ms |
| App code: `didFinishLaunching` + scene connect (SwiftData container, dependencies) | **~13 ms** |
| First frame (first SwiftUI render of the Trending tab) | ~195 ms |

The app's own startup work is small; most of the time is the system creating the process (which Instruments' own attach also inflates) and the first render. The first launch right after installing is slower (~1.5 s) while iOS builds its caches, as with any app.

> The Release build for this run was signed with a free Apple account without the App Group entitlement, so the widget snapshot was skipped. That doesn't affect launch or scrolling.

## On the simulator



### Image cache ([ADR 0006](adr/0006-actor-image-cache.md))
A 342×513 JPEG (TMDB's `w342` poster size), 50 posters per iteration, 5 iterations. No network: a "miss" gets the bytes from memory, so it measures decoding and the disk write, not the download.

| Level | Per poster | What it costs |
|-------|-----------:|---------------|
| Memory hit | **~17 µs** | Dictionary lookup + LRU update on the actor |
| Disk hit | **~7.6 ms** | File read + JPEG decode + `byPreparingForDisplay()` |
| Miss (no network) | **~9.2 ms** | Decode + prepare + atomic write to disk |

A memory hit is ~450× cheaper than a disk hit, which is why the memory level holds 150 decoded posters (a few screens of the grid). Disk hits and misses decode off the main thread (`@concurrent`), so these milliseconds don't block scrolling.

### Launch
| Metric | Average (5 runs) |
|--------|-----------------:|
| Launch until the app responds to input | **1.49 s** |

Canned data (`-ui-testing`), so the network isn't part of the number. This includes the SwiftData container and String Catalog setup, Debug-build overhead and the XCUITest launch handshake.

### Scrolling Trending
A fast fling through a 200-title grid (10 pages of canned data, `-ui-testing-large-feed`), 5 iterations.

| Metric | Average |
|--------|--------:|
| Peak memory | **64 MB** |
| Memory change per fling | **~0 MB** (no growth between iterations) |

The test also collects `XCTOSSignpostMetric.scrollDecelerationMetric`. The simulator only reports the scroll duration; hitch ratio and frame rate are in the device section above. Posters are placeholders in this test, since image cost is measured separately.

## How to rerun
```bash
scripts/perf.sh "iPhone 17 Pro"
```
The UI performance tests are skipped unless `TEST_RUNNER_TIMESKIP_PERF=1` (the script sets it). CI doesn't run them: shared runners are too noisy for numbers worth comparing.

On a connected iPhone (your own team ID; the free-account profile has no App Group, hence the empty entitlements):
```bash
TEST_RUNNER_TIMESKIP_PERF=1 xcodebuild test -project Timeskip.xcodeproj -scheme Timeskip \
  -destination 'id=<device id>' DEVELOPMENT_TEAM=<team id> CODE_SIGN_ENTITLEMENTS= \
  -allowProvisioningUpdates -only-testing:TimeskipUITests/PerformanceTests
```
For the Release launch breakdown: build with `-configuration Release`, install, then `xcrun xctrace record --template 'App Launch' --device <device id> --launch -- com.baggioto.Timeskip`.
