import XCTest

@MainActor
extension XCUIApplication {
    static func cashly() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    var windowWidth: CGFloat {
        windows.firstMatch.frame.width
    }

    var fitsInspector: Bool {
        windowWidth >= 960
    }

    var layoutDescription: String {
        let columns = ["Home", "Converter"].map { title in
            let bar = navigationBars[title]
            guard bar.exists else { return "\(title): hidden" }
            return "\(title): x \(Int(bar.frame.minX)), width \(Int(bar.frame.width))"
        }
        return (["window: \(Int(windowWidth))"] + columns).joined(separator: "\n")
    }

    var showsHome: Bool {
        navigationBars["Home"].exists
    }

    func finishOnboarding() {
        let start = buttons["Get Started"]
        guard start.waitForExistence(timeout: 20) else { return }
        start.tap()
        let name = textFields["Your Name"]
        name.tap()
        name.typeText("Cashly Tests")
        buttons["Continue"].tap()
        buttons["Skip for Now"].tap()
        let done = buttons["Start Using Cashly"]
        if done.waitForExistence(timeout: 10) { done.tap() }
    }

    func dismissPaywall() {
        let close = buttons["Close"]
        if close.waitForExistence(timeout: 6) { close.tap() }
    }

    func waitForHome() -> Bool {
        navigationBars["Home"].waitForExistence(timeout: 20)
    }

    func openConverter() -> Bool {
        buttons["Converter"].firstMatch.tap()
        return navigationBars["Converter"].waitForExistence(timeout: 10)
    }

    func closeRoute() {
        let close = buttons["Close"]
        if close.exists {
            close.tap()
        } else {
            navigationBars["Converter"].buttons.firstMatch.tap()
        }
    }

    #if os(iOS)
        func rotate(to orientation: UIDeviceOrientation) {
            let before = windowWidth
            XCUIDevice.shared.orientation = orientation
            let deadline = Date().addingTimeInterval(10)
            while windowWidth == before, Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        }
    #endif
}
