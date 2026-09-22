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
        XCTAssertFalse(app.buttons["doseStatus"].exists)
        XCTAssertFalse(app.buttons["Planned"].exists)
        XCTAssertFalse(app.buttons["Skipped"].exists)
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
    @MainActor func testLogDoseOnlyCreatesTakenDoses() {
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
        app.terminate()
        app.launchArguments = ["--uitest"]
        app.launch()
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["0.5 mg · Semaglutide"].waitForExistence(timeout: 5))
    }
    @MainActor func testEveryFewDaysScheduleCanBeSaved() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest", "--reset-test-journal"]
        app.launch()
        app.buttons["Treatment"].tap()
        app.buttons["editSchedule"].tap()
        app.segmentedControls.buttons["Every few days"].tap()
        XCTAssertTrue(app.staticTexts["Every 4 days"].exists)
        XCTAssertTrue(app.staticTexts["Starts"].exists)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Every 4 days"].waitForExistence(timeout: 5))
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
    @MainActor func testHomeCardsOpenTheirOwnScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        // The whole medication card is the tap target, not only its chart.
        let medicationCard = app.descendants(matching: .any).matching(identifier: "medicationCard").firstMatch
        XCTAssertTrue(medicationCard.waitForExistence(timeout: 5))
        medicationCard.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "medicationDetailChart").firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // The weight tile moves to the Progress tab rather than opening a sheet.
        app.swipeUp()
        app.descendants(matching: .any).matching(identifier: "weightCard").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["pageHeader-Progress"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Done"].exists)
        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["logDose"].waitForExistence(timeout: 5))
    }
    @MainActor func testMedicationChartTapAndFutureDrag() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()

        let homeChart = app.descendants(matching: .any).matching(identifier: "medicationChart").firstMatch
        XCTAssertTrue(homeChart.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Dashed line includes'")).firstMatch.exists)
        capture("Medication Home")
        homeChart.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
        let detailChart = app.descendants(matching: .any).matching(identifier: "medicationDetailChart").firstMatch
        XCTAssertTrue(detailChart.waitForExistence(timeout: 5), "Tapping the plotted line should open Medication")

        let amount = app.staticTexts["liveMedicationAmount"]
        let number = NumberFormatter()
        number.numberStyle = .decimal
        guard let current = number.number(from: amount.label)?.doubleValue else { XCTFail("Expected a numeric live estimate"); return }
        let start = detailChart.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.5))
        let future = detailChart.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.2, thenDragTo: future)
        XCTAssertTrue(app.buttons["Live"].exists, "The future selection should remain visible after the drag")
        guard let futureAmount = number.number(from: amount.label)?.doubleValue else { XCTFail("Expected a numeric future estimate"); return }
        XCTAssertGreaterThan(futureAmount, current + 0.1, "The readout should include scheduled future doses shown by the curve")
        capture("Medication future selection")
        app.buttons["Live"].tap()
        XCTAssertFalse(app.buttons["Live"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["About medication estimates"].tap()
        XCTAssertTrue(app.navigationBars["About this graph"].waitForExistence(timeout: 5))
    }
    @MainActor func testWeightCardTapTargets() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.swipeUp()
        capture("Weight Home")

        for point in [CGVector(dx: 0.15, dy: 0.15), CGVector(dx: 0.18, dy: 0.5), CGVector(dx: 0.8, dy: 0.5), CGVector(dx: 0.5, dy: 0.9)] {
            let card = app.descendants(matching: .any).matching(identifier: "weightCard").firstMatch
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            card.coordinate(withNormalizedOffset: point).tap()
            XCTAssertTrue(app.staticTexts["pageHeader-Progress"].waitForExistence(timeout: 5), "Weight card tap at \(point) should open Progress")
            app.buttons["Home"].tap()
        }

        app.buttons["logWeight"].tap()
        XCTAssertTrue(app.textFields["weightAmount"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["pageHeader-Progress"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertGreaterThanOrEqual(app.buttons["logWeight"].frame.width, 50)

        app.buttons["Progress"].tap()
        let currentWeight = app.descendants(matching: .any).matching(identifier: "currentWeightCard").firstMatch
        XCTAssertTrue(currentWeight.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Latest recorded weight"].exists)
        XCTAssertTrue(app.staticTexts["195.1"].exists)
        Thread.sleep(forTimeInterval: 1)
        capture("Weight Progress Top")
        let addWeight = app.buttons["Log weight"]
        XCTAssertGreaterThanOrEqual(addWeight.frame.width, 50)
        addWeight.tap()
        XCTAssertTrue(app.textFields["weightAmount"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        capture("Weight Progress Chart")
    }
    @MainActor func testCustomDatesCanBeChosenAndTheScheduleCleared() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitest"]
        app.launch()
        app.buttons["Treatment"].tap()
        app.buttons["editSchedule"].tap()
        app.segmentedControls.buttons["Custom"].tap()
        let picker = app.descendants(matching: .any).matching(identifier: "customDatePicker").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        // Pick two days from the visible month grid.
        let days = picker.buttons.allElementsBoundByIndex.filter { $0.isHittable }
        XCTAssertGreaterThan(days.count, 2, "The calendar should offer selectable days")
        days[days.count - 1].tap()
        days[days.count - 2].tap()
        XCTAssertTrue(app.staticTexts["Upcoming"].waitForExistence(timeout: 3))
        capture("schedule-custom")
        app.buttons["Save"].tap()
        // Wait for the sheet to finish dismissing before reopening it.
        XCTAssertTrue(app.navigationBars["Your schedule"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["editSchedule"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Custom ·'")).firstMatch.exists)
        capture("treatment-custom")

        // Clearing leaves no schedule at all.
        app.buttons["editSchedule"].tap()
        XCTAssertTrue(app.navigationBars["Your schedule"].waitForExistence(timeout: 5))
        // Form rows are lazy, so scroll the calendar past before looking for the clear action.
        let clear = app.buttons["clearSchedule"]
        for _ in 0..<6 where !clear.exists { app.swipeUp() }
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        app.alerts.buttons["Clear"].tap()
        XCTAssertTrue(app.staticTexts["No schedule set"].waitForExistence(timeout: 5))
        capture("treatment-cleared")
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
