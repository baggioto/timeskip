#!/usr/bin/env bash
# Runs the performance tests on a simulator and prints one line per metric.
# Usage: scripts/perf.sh ["iPhone 17 Pro"]
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 17 Pro}"
LOG=$(mktemp)

TEST_RUNNER_TIMESKIP_PERF=1 xcodebuild test -project Timeskip.xcodeproj -scheme Timeskip \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -only-testing:TimeskipTests/ImageCachePerformanceTests \
  -only-testing:TimeskipUITests/PerformanceTests > "$LOG" 2>&1 || { tail -30 "$LOG"; exit 1; }

echo "Device: $DEVICE (simulator), Debug build"
# "...PerformanceTests testLaunchTime]' measured [Duration (...), s] average: 1.487, ..." → "testLaunchTime  Duration (...), s  1.487"
grep "measured \[" "$LOG" | sed -E "s/.* (test[A-Za-z]+)\]' measured \[([^]]+)\] average: ([-0-9.]+),.*/\1|\2|\3/" |
  awk -F'|' '{ printf "%-24s %-55s %s\n", $1, $2, $3 }'
rm "$LOG"
