import XCTest

final class StillUITests: XCTestCase {
    @MainActor func testPreviewScreensAndLogging() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.tabBars.buttons["Summary"].tap()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 10))
        capture("Summary")
        app.buttons["logDose"].tap()
        XCTAssertTrue(app.textFields["doseAmount"].waitForExistence(timeout: 3))
        capture("Log dose")
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Progress"].tap()
        capture("Progress")
        app.tabBars.buttons["Journal"].tap()
        capture("Journal")
        app.tabBars.buttons["Settings"].tap()
        capture("Settings")
        app.buttons["Schedule & reminders"].tap()
        capture("Schedule")
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Summary"].tap()
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
