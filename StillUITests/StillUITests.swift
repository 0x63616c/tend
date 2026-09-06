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
    @MainActor func testReopeningKilogramWeightDoesNotConvertItAgain() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.buttons["Settings"].tap()
        app.buttons["Weight unit, lb"].tap()
        app.buttons["kg"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Journal"].tap()
        app.staticTexts["88.5 kg"].tap()
        XCTAssertEqual(app.textFields["weightAmount"].value as? String, "88.5")
    }
    @MainActor func testWeightSavesWithKeyboardOpenAndSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.tabBars.buttons["Progress"].tap()
        app.buttons["Log weight"].tap()
        let field = app.textFields["weightAmount"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("200.3")
        XCTAssertTrue(app.buttons["saveWeight"].isHittable, "Save must remain reachable above the keyboard")
        app.buttons["saveWeight"].tap()
        XCTAssertFalse(field.waitForExistence(timeout: 1))
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["200.3 lb"].waitForExistence(timeout: 5))
        app.staticTexts["200.3 lb"].tap()
        XCTAssertEqual(app.textFields["weightAmount"].value as? String, "200.3")
    }
    @MainActor func testDoseCanBeSavedThenChangedToSkippedAndPersisted() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.buttons["logDose"].tap()
        let field = app.textFields["doseAmount"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("0.5")
        app.buttons["saveDose"].tap()
        app.tabBars.buttons["Journal"].tap()
        let record = app.staticTexts["0.5 mg · Semaglutide"]
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.tap()
        app.segmentedControls.buttons["Skipped"].tap()
        XCTAssertFalse(field.exists)
        app.buttons["saveDose"].tap()
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["Skipped · Semaglutide"].waitForExistence(timeout: 5))
    }
    @MainActor func testReminderPreviewIsConditionalAndDeliversANotification() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.tabBars.buttons["Treatment"].tap()
        app.buttons["editSchedule"].tap()
        XCTAssertFalse(app.buttons["Send test notification"].exists)
        app.switches["Remind me"].switches.firstMatch.tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Send test notification"].waitForExistence(timeout: 3))
        app.buttons["Send test notification"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Allow"].waitForExistence(timeout: 3) { springboard.buttons["Allow"].tap() }
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(springboard.staticTexts["Time for your check-in"].waitForExistence(timeout: 15))
        capture("Actual reminder notification")
    }
    @MainActor func testHomeGraphsOpenDetailsAndCanBeClosed() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        let medicationChart = app.descendants(matching: .any).matching(identifier: "medicationChart").firstMatch
        XCTAssertTrue(medicationChart.waitForExistence(timeout: 5))
        medicationChart.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "medicationDetailChart").firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.swipeUp()
        app.descendants(matching: .any).matching(identifier: "weightCard").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["logDose"].exists)
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
