# Performance

Measured with XCTest metrics (`measure(metrics:)`), so anyone can rerun them: `scripts/perf.sh`.

> **These are simulator numbers from a Debug build** (iPhone 17 Pro simulator, Xcode 26, on a Mac). They're useful for comparing changes over time, not as real-device figures: a simulator uses the Mac's CPU and disk. The real-device pass with Instruments is on the [roadmap](ROADMAP.md).

Last run: 2026-11-27, v0.3.

## Image cache ([ADR 0006](adr/0006-actor-image-cache.md))
A 342×513 JPEG (TMDB's `w342` poster size), 50 posters per iteration, 5 iterations. No network: a "miss" gets the bytes from memory, so it measures decoding and the disk write, not the download.

| Level | Per poster | What it costs |
|-------|-----------:|---------------|
| Memory hit | **~17 µs** | Dictionary lookup + LRU update on the actor |
| Disk hit | **~7.6 ms** | File read + JPEG decode + `byPreparingForDisplay()` |
| Miss (no network) | **~9.2 ms** | Decode + prepare + atomic write to disk |

A memory hit is ~450× cheaper than a disk hit, which is why the memory level holds 150 decoded posters (a few screens of the grid). Disk hits and misses decode off the main thread (`@concurrent`), so these milliseconds don't block scrolling.

## Launch
| Metric | Average (5 runs) |
|--------|-----------------:|
| Launch until the app responds to input | **1.49 s** |

Canned data (`-ui-testing`), so the network isn't part of the number. This includes the SwiftData container and String Catalog setup, Debug-build overhead and the XCUITest launch handshake.

## Scrolling Trending
A fast fling through a 200-title grid (10 pages of canned data, `-ui-testing-large-feed`), 5 iterations.

| Metric | Average |
|--------|--------:|
| Peak memory | **64 MB** |
| Memory change per fling | **~0 MB** (no growth between iterations) |

The test also collects `XCTOSSignpostMetric.scrollDecelerationMetric`. On a device that reports the hitch time ratio and frame rate; the simulator only reports the scroll duration, so there's no hitch number here yet. Posters are placeholders in this test, since image cost is measured above.

## How to rerun
```bash
scripts/perf.sh "iPhone 17 Pro"
```
The UI performance tests are skipped unless `TEST_RUNNER_TIMESKIP_PERF=1` (the script sets it). CI doesn't run them: shared runners are too noisy for numbers worth comparing.
