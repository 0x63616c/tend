import XCTest

final class StillUITests: XCTestCase {
    @MainActor func testPrimaryPageHeadersShareOnePosition() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()

        let home = app.staticTexts["pageHeader-Tendr"]
        XCTAssertTrue(home.waitForExistence(timeout: 10))
        let origin = home.frame.origin

        for (tab, title) in [("Treatment", "Treatment"), ("Progress", "Progress"), ("Journal", "Journal"), ("Settings", "Settings")] {
            app.buttons[tab].tap()
            let header = app.staticTexts["pageHeader-\(title)"]
            XCTAssertTrue(header.waitForExistence(timeout: 3))
            XCTAssertEqual(header.frame.minX, origin.x, accuracy: 1)
            XCTAssertEqual(header.frame.minY, origin.y, accuracy: 1)
        }
    }

    @MainActor func testPreviewScreensAndLogging() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.images["medicationTrendIndicator"].exists)
        XCTAssertFalse(app.buttons["Include explicitly planned doses"].exists)
        capture("Home")
        app.buttons["Vial details"].tap()
        XCTAssertTrue(app.textFields["Concentration"].waitForExistence(timeout: 3))
        capture("Edit Vial")
        app.buttons["Cancel"].tap()
        app.buttons["logDose"].tap()
        XCTAssertTrue(app.textFields["doseAmount"].waitForExistence(timeout: 3))
        capture("Log dose")
        app.buttons["Cancel"].tap()
        app.buttons["Progress"].tap()
        capture("Progress")
        app.buttons["Journal"].tap()
        capture("Journal")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Connect Apple Health"].exists)
        capture("Settings")
        app.buttons["Home"].tap()
    }
    @MainActor func testPolishedFiltersAndVials() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 10))
        capture("Polish Home")
        app.swipeUp()
        capture("Polish Home collapsed")
        app.buttons["Treatment"].tap()
        capture("Polish Treatment")
        app.buttons["Journal"].tap()
        app.buttons["Doses"].tap()
        XCTAssertTrue(app.buttons["Doses"].isSelected)
        XCTAssertFalse(app.staticTexts["Weight"].exists)
        app.buttons["Weight"].tap()
        XCTAssertTrue(app.buttons["Weight"].isSelected)
        app.buttons["All"].tap()
        XCTAssertTrue(app.buttons["All"].isSelected)
        capture("Polish Journal")
        app.buttons["Progress"].tap()
        if !app.buttons["Month"].isHittable { app.swipeUp() }
        app.buttons["Month"].tap()
        XCTAssertTrue(app.buttons["Month"].isSelected)
        app.buttons["Year"].tap()
        XCTAssertTrue(app.buttons["Year"].isSelected)
        capture("Polish Progress")
    }
    @MainActor func testLivePrecisionIsAlwaysSevenDecimals() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        XCTAssertEqual(app.staticTexts["liveMedicationAmount"].label, "0.0000000")
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        XCTAssertEqual(app.staticTexts["liveMedicationAmount"].label, "0.0000000")
    }
    @MainActor func testDosePreferencesSurviveRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.buttons["Settings"].tap()
        app.buttons["Dose entry"].tap()
        app.segmentedControls.buttons["Units"].tap()
        app.switches["I use a U-100 syringe"].tap()
        app.buttons["Save"].tap()
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        app.buttons["logDose"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Units"].isSelected)
        XCTAssertFalse(app.switches["My syringe is U-100"].exists)
        XCTAssertFalse(app.staticTexts["U-100 · 100 units = 1 mL"].exists)
        app.segmentedControls.buttons["mg"].tap()
        app.textFields["doseAmount"].tap()
        app.textFields["doseAmount"].typeText("0.15")
        app.buttons["saveDose"].tap()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 3))
        app.buttons["logDose"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["mg"].isSelected)
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
        app.buttons["doseStatus"].tap()
        XCTAssertTrue(app.buttons["Skipped"].waitForExistence(timeout: 2))
        app.buttons["Skipped"].tap()
        app.buttons["doseStatus"].tap()
        XCTAssertTrue(app.buttons["Taken"].waitForExistence(timeout: 2))
        app.buttons["Taken"].tap()
        XCTAssertEqual(field.value as? String, "3")
        app.buttons["doseStatus"].tap()
        XCTAssertTrue(app.buttons["Planned"].waitForExistence(timeout: 2))
        app.buttons["Planned"].tap()
        app.buttons["doseStatus"].tap()
        XCTAssertTrue(app.buttons["Taken"].waitForExistence(timeout: 2))
        app.buttons["Taken"].tap()
        XCTAssertEqual(field.value as? String, "3")
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
        app.buttons["Weight unit, lbs"].tap()
        app.buttons["kg"].tap()
        app.buttons["Journal"].tap()
        app.staticTexts["88.5 kg"].tap()
        XCTAssertEqual(app.textFields["weightAmount"].value as? String, "88.5")
    }
    @MainActor func testWeightSavesWithKeyboardOpenAndSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.buttons["Progress"].tap()
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
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["200.3 lbs"].waitForExistence(timeout: 5))
        app.staticTexts["200.3 lbs"].tap()
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
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 3))
        app.buttons["Journal"].tap()
        let record = app.staticTexts["0.5 mg · Semaglutide"]
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.tap()
        app.buttons["doseStatus"].tap()
        app.buttons["Skipped"].tap()
        XCTAssertFalse(field.exists)
        app.buttons["saveDose"].tap()
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["Skipped · Semaglutide"].waitForExistence(timeout: 5))
    }
    @MainActor func testReminderTimeIsConditionalWithoutPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.buttons["Treatment"].tap()
        app.buttons["editSchedule"].tap()
        XCTAssertFalse(app.staticTexts["Time"].exists)
        XCTAssertFalse(app.buttons["Send test notification"].exists)
        app.switches["Remind me"].switches.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Time"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Notification preview"].exists)
        XCTAssertFalse(app.buttons["Send test notification"].exists)
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
