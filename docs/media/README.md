# README media

The GIFs are recorded from the simulator while a UI test drives the real app (`TimeskipUITests/DemoRecordingTests.swift`). That test is skipped unless `TIMESKIP_DEMO=1`, so CI never runs it.

```bash
D="iPhone 17 Pro"
xcodebuild build-for-testing -project Timeskip.xcodeproj -scheme Timeskip -destination "platform=iOS Simulator,name=$D"
xcrun simctl uninstall "$D" com.baggioto.Timeskip   # start from an empty watchlist
xcrun simctl status_bar "$D" override --time "9:41" --batteryState charged --batteryLevel 100

xcrun simctl io "$D" recordVideo --codec h264 --force browse.mov &
TEST_RUNNER_TIMESKIP_DEMO=1 xcodebuild test-without-building -project Timeskip.xcodeproj -scheme Timeskip \
  -destination "platform=iOS Simulator,name=$D" -only-testing:TimeskipUITests/DemoRecordingTests/testDemoBrowse
kill -INT %1

# Trim to the app (check the start/end seconds), speed up 1.3x, hold the last frame, 10 fps, 280 px wide:
ffmpeg -ss <start> -to <end> -i browse.mov -vf "setpts=PTS/1.3,tpad=stop_mode=clone:stop_duration=2.5,fps=10,scale=280:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -loop 0 browse.gif
```

Repeat with `testDemoEpisodes` for `episodes.gif`. Needs a TMDB token in `Config/Secrets.xcconfig` (live data).
