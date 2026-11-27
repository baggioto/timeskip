import XCTest

/// Smoke tests for the main flows. The app runs with `-ui-testing`: canned data, nothing persisted, no network.
nonisolated final class TimeskipUITests: XCTestCase {
    @MainActor
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    @MainActor
    func testAddFromDetailsShowsUpInWatchlist() {
        let app = launch()
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'The Long Night'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        let add = app.buttons["Add to Watchlist"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        XCTAssertTrue(app.buttons["In Watchlist"].waitForExistence(timeout: 2))

        tab("Watchlist", in: app).tap()
        XCTAssertTrue(app.staticTexts["The Long Night"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Your watchlist is empty"].exists)
    }

    @MainActor
    func testSearchShowsMatchingTitle() {
        let app = launch()
        tab("Search", in: app).tap()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("signal")

        XCTAssertTrue(app.staticTexts["Signal Lost"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Paper Moons"].exists)
    }

    @MainActor
    func testEmptyWatchlistAndAbout() {
        let app = launch()
        tab("Watchlist", in: app).tap()
        XCTAssertTrue(app.staticTexts["Your watchlist is empty"].waitForExistence(timeout: 5))

        app.buttons["About"].tap()
        XCTAssertTrue(
            app.staticTexts["This product uses the TMDB API but is not endorsed or certified by TMDB."]
                .waitForExistence(timeout: 2))
    }

    @MainActor
    func testWatchingAnEpisodeAddsTheShowToUpNext() {
        let app = launch()
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Signal Lost'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        let season = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Season 1'")).firstMatch
        XCTAssertTrue(season.waitForExistence(timeout: 5))
        season.tap()

        let firstEpisode = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Chapter 1'")).firstMatch
        XCTAssertTrue(firstEpisode.waitForExistence(timeout: 5))
        firstEpisode.tap()

        tab("Watchlist", in: app).tap()
        XCTAssertTrue(app.staticTexts["Up next"].waitForExistence(timeout: 2))
    }

    /// Landscape on iPhone, any orientation on iPad: the grid and details stay usable.
    /// The screenshots are kept in the test results for a visual check.
    @MainActor
    func testLandscapeGridAndDetails() {
        let app = launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { @MainActor in XCUIDevice.shared.orientation = .portrait }

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Signal Lost'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        attachScreenshot(app, named: "Landscape grid")
        card.tap()

        let add = app.buttons["Add to Watchlist"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertTrue(add.isHittable)
        XCTAssertTrue(app.staticTexts["Signal Lost"].isHittable)
        attachScreenshot(app, named: "Landscape details")
    }

    /// iPhone has a classic tab bar; on iPad the floating tab bar isn't exposed as a `TabBar`.
    @MainActor
    private func tab(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let classic = app.tabBars.buttons[name]
        return classic.exists ? classic : app.buttons.matching(identifier: name).firstMatch
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
