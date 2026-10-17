import XCTest

final class InspectorLayoutTests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    @MainActor func testRoutesOpenBesideOnlyWhenTheWindowFitsTheInspector() {
        let app = launch()
        XCTAssertTrue(app.openConverter())
        XCTAssertEqual(app.showsHome, app.fitsInspector)
        capture(app, "converter")
    }

    #if os(iOS)
        @MainActor func testAnOpenRouteStaysWhereItIsWhenTheIPadRotates() throws {
            try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
            let app = launch()
            XCTAssertTrue(app.openConverter())
            let wasBeside = app.showsHome
            capture(app, "portrait-converter")
            app.rotate(to: .landscapeLeft)
            XCTAssertTrue(app.navigationBars["Converter"].exists)
            XCTAssertEqual(app.showsHome, wasBeside)
            capture(app, "landscape-converter-kept")
            app.closeRoute()
            XCTAssertTrue(app.waitForHome())
            XCTAssertTrue(app.openConverter())
            XCTAssertEqual(app.showsHome, app.fitsInspector)
            capture(app, "landscape-converter")
            app.rotate(to: .portrait)
            XCTAssertTrue(app.navigationBars["Converter"].exists)
            capture(app, "portrait-converter-kept")
        }
    #endif

    @MainActor private func launch() -> XCUIApplication {
        #if os(iOS)
            XCUIDevice.shared.orientation = .portrait
        #endif
        let app = XCUIApplication.cashly()
        app.launch()
        app.finishOnboarding()
        app.dismissPaywall()
        XCTAssertTrue(app.waitForHome())
        capture(app, "home")
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let label = "\(name)-\(Int(app.windowWidth))pt"
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = label
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let layout = XCTAttachment(string: app.layoutDescription)
        layout.name = "\(label)-layout"
        layout.lifetime = .keepAlways
        add(layout)
    }
}
