import XCTest

/// Launch time, scroll smoothness and memory, measured on the simulator.
/// Skipped unless run with `TEST_RUNNER_TIMESKIP_PERF=1` (CI runners are too noisy for useful numbers).
/// `scripts/perf.sh` runs them and prints a summary; results are in docs/PERFORMANCE.md.
nonisolated final class PerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TIMESKIP_PERF"] == "1", "Performance runs only")
    }

    @MainActor
    private func makeApp(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + extraArguments
        return app
    }

    /// Time from launch until the app responds to input (canned data, so no network in the number).
    @MainActor
    func testLaunchTime() {
        let app = makeApp()
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
        }
    }

    /// Hitches and frame rate while a fast fling decelerates through a 200-title Trending grid,
    /// plus the app's memory over the run. Posters are placeholders here: image decoding is
    /// measured on its own in `ImageCachePerformanceTests`.
    @MainActor
    func testTrendingScroll() {
        let app = makeApp(["-ui-testing-large-feed"])
        app.launch()
        let grid = app.scrollViews.firstMatch
        XCTAssertTrue(grid.buttons.firstMatch.waitForExistence(timeout: 5))
        // Load a few pages first, so pagination doesn't land in the middle of a measured fling.
        for _ in 0..<4 { grid.swipeUp(velocity: .fast) }
        grid.swipeDown(velocity: 4000)

        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStop]
        measure(
            metrics: [XCTOSSignpostMetric.scrollDecelerationMetric, XCTMemoryMetric(application: app)],
            options: options
        ) {
            grid.swipeUp(velocity: .fast)
            stopMeasuring()
            grid.swipeDown(velocity: .fast)
        }
    }
}
