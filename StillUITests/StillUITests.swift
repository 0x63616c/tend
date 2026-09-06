import XCTest

final class StillUITests: XCTestCase {
    @MainActor func testPreviewScreensAndLogging() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 10))
        capture("Home")
        app.buttons["logDose"].tap()
        XCTAssertTrue(app.textFields["doseAmount"].waitForExistence(timeout: 3))
        capture("Log dose")
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Progress"].tap()
        capture("Progress")
        app.tabBars.buttons["Journal"].tap()
        capture("Journal")
        app.tabBars.buttons["Discover"].tap()
        XCTAssertTrue(app.staticTexts["READ. COOK. RESET."].waitForExistence(timeout: 3))
        capture("Discover")
        app.buttons["Recipes"].tap()
        app.staticTexts["The five-minute\nyogurt bowl"].tap()
        XCTAssertTrue(app.staticTexts["Ingredients"].waitForExistence(timeout: 3))
        capture("Recipe")
        app.tabBars.buttons["Home"].tap()
    }
    @MainActor func testChangingDoseUnitsPreservesTheDose() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.buttons["logDose"].tap()
        let field = app.textFields["doseAmount"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("3")
        app.segmentedControls.buttons["mg"].tap()
        XCTAssertEqual(field.value as? String, "0.15")
        app.segmentedControls.buttons["mL"].tap()
        XCTAssertEqual(field.value as? String, "0.03")
        app.segmentedControls.buttons["Units"].tap()
        XCTAssertEqual(field.value as? String, "3")
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
