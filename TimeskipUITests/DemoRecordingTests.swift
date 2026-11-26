import XCTest

/// Drives the real app (live TMDB data) at a human pace, to record the README GIFs.
/// Skipped unless run with `TEST_RUNNER_TIMESKIP_DEMO=1`, so CI (which has no token) never runs it.
/// See docs/media/README.md for the recording steps.
nonisolated final class DemoRecordingTests: XCTestCase {
    @MainActor
    private func launch() throws -> XCUIApplication {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TIMESKIP_DEMO"] == "1", "Demo recording only")
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    private func pause(_ seconds: Double = 1.2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    /// Trending → scroll → details → add to watchlist → Watchlist tab.
    @MainActor
    func testDemoBrowse() throws {
        let app = try launch()
        let grid = app.scrollViews.firstMatch
        XCTAssertTrue(grid.buttons.firstMatch.waitForExistence(timeout: 10))
        pause(2)

        grid.swipeUp(velocity: .slow)
        pause()
        grid.swipeDown(velocity: .slow)
        pause()

        app.buttons["This week"].tap()
        pause(2.5)

        grid.buttons.element(boundBy: 1).tap()
        pause(2.5)
        app.swipeUp(velocity: .slow)
        pause()
        app.swipeDown(velocity: .slow)
        pause()

        app.buttons["Add to Watchlist"].tap()
        pause(1.5)

        app.tabBars.buttons["Watchlist"].tap()
        pause(2.5)
    }

    /// Search → show → season → mark episodes → "Up next".
    @MainActor
    func testDemoEpisodes() throws {
        let app = try launch()
        app.tabBars.buttons["Search"].tap()
        pause()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        for letter in "Severance" {
            field.typeText(String(letter))
            Thread.sleep(forTimeInterval: 0.12)
        }
        pause(2)

        let result = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Severance'")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        pause(2)

        app.swipeUp(velocity: .slow)
        pause()

        let season = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Season 1'")).firstMatch
        XCTAssertTrue(season.waitForExistence(timeout: 10))
        season.tap()
        pause(2)

        for number in 1...3 {
            let episode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "S1 · E\(number),"))
                .firstMatch
            XCTAssertTrue(episode.waitForExistence(timeout: 10))
            episode.tap()
            pause(0.8)
        }
        pause()

        app.tabBars.buttons["Watchlist"].tap()
        pause(3)
    }
}
