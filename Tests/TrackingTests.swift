import XCTest
@testable import StillCore

final class TrackingTests: XCTestCase {
    func testOlderJournalLoadsWithNewFieldsDefaultedAndFutureSchemaIsRejected() throws {
        let old = Data(#"{"version":1,"weights":[],"doses":[],"medication":"Semaglutide"}"#.utf8)
        let journal = try JSONDecoder().decode(Journal.self, from: old)
        XCTAssertEqual(journal.checkIns, [])
        XCTAssertEqual(journal.vials, [])
        XCTAssertEqual(journal.halfLifeDays, 7)
        XCTAssertEqual(journal.liveDecimalPlaces, 5)
        XCTAssertEqual(journal.resolvedMedicationModel, .semaglutide)
        XCTAssertThrowsError(try JSONDecoder().decode(Journal.self, from: Data(#"{"version":999}"#.utf8)))
    }
    func testNewJournalDoesNotInventADosingSchedule() {
        XCTAssertTrue(Journal().schedule.occurrences(after: Date(), count: 1).isEmpty)
    }
    func testWeightSummaryUsesChronologyAndExcludesFutureMeasurements() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let summary = WeightSummary(entries: [
            WeightEntry(date: start.addingTimeInterval(14 * 86400), kilograms: 98),
            WeightEntry(date: start, kilograms: 100),
            WeightEntry(date: start.addingTimeInterval(30 * 86400), kilograms: 80)
        ], now: start.addingTimeInterval(15 * 86400))
        XCTAssertEqual(summary.latest, 98)
        XCTAssertEqual(summary.lost, 2)
        XCTAssertEqual(summary.weeklyChange, -1)
    }
    func testDoseRejectsFutureTakenAndInvalidAmountsButAcceptsPlans() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var dose = DoseEntry(date: now.addingTimeInterval(3600), medication: "Semaglutide", milligrams: 0.5)
        XCTAssertThrowsError(try dose.validate(now: now))
        dose.status = .planned
        XCTAssertNoThrow(try dose.validate(now: now))
        dose.milligrams = -1
        XCTAssertThrowsError(try dose.validate(now: now))
    }
    func testTwiceWeeklyScheduleKeepsLocalTimeAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 6, hour: 12))!
        var schedule = DoseSchedule()
        schedule.weekdays = [1, 4]
        let dates = schedule.occurrences(after: start, count: 3, calendar: calendar)
        XCTAssertEqual(dates.map { calendar.component(.day, from: $0) }, [8, 11, 15])
        XCTAssertEqual(dates.map { calendar.component(.hour, from: $0) }, [9, 9, 9])
    }
    func testJournalPersistsEditsAndPreservesMedicationHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = JournalFile(url: directory.appendingPathComponent("journal.json"))
        var journal = Journal()
        journal.doses = [DoseEntry(date: Date(timeIntervalSince1970: 1700000000), medication: "Semaglutide", milligrams: 0.5, concentration: 5, note: "A quiet morning")]
        try file.save(journal)
        var edited = try file.load()
        XCTAssertEqual(edited, journal)
        guard !edited.doses.isEmpty else { return }
        edited.medication = "Tirzepatide"
        edited.doses[0].note = "Updated note"
        try file.save(edited)
        let reloaded = try file.load()
        XCTAssertEqual(reloaded.doses[0].medication, "Semaglutide")
        XCTAssertEqual(reloaded.doses[0].note, "Updated note")
    }
    func testOverdueRemainsUntilExplicitlyLoggedOrSkippedWithoutMovingSchedule() {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = cal.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 9))!
        var schedule = DoseSchedule(); schedule.weekdays = [2, 5]; schedule.startDate = monday
        let tuesday = monday.addingTimeInterval(86400)
        XCTAssertEqual(schedule.outstanding(asOf: tuesday, doses: [], calendar: cal), [monday])
        let late = DoseEntry(date: tuesday, scheduledDate: monday, medication: "Semaglutide", milligrams: 0.5)
        XCTAssertEqual(schedule.outstanding(asOf: tuesday, doses: [late], calendar: cal), [])
        XCTAssertEqual(cal.component(.weekday, from: schedule.occurrences(after: tuesday, count: 1, calendar: cal)[0]), 5)
    }
    func testSyringeUnitsRequireScaleAndConvertUsingVialConcentration() throws {
        let vial = Vial(received: Date(), medication: "Semaglutide", concentration: 5, volumeML: 2)
        XCTAssertEqual(vial.totalMilligrams, 10)
        XCTAssertEqual(try vial.milligrams(units: 3, unitsPerML: 100), 0.15, accuracy: 0.000001)
        XCTAssertThrowsError(try vial.milligrams(units: 3, unitsPerML: 0))
        XCTAssertThrowsError(try vial.milligrams(units: -3, unitsPerML: 100))
    }
    func testAbsorptionModelMatchesIndependentIntegrationAndStartsAtZero() {
        let start = Date(timeIntervalSince1970: 1700000000)
        let dose = DoseEntry(date: start, medication: "Semaglutide", milligrams: 1)
        // Fixed values from scripts/absorption_reference.py (independent RK4 integration).
        for (model, expected) in [(MedicationModel.semaglutide, [0.021060421626, 0.354583889016, 0.563089039286, 0.460457116966, 0.227180051501]), (.tirzepatide, [0.029098184638, 0.416136562924, 0.536849850677, 0.376834602383, 0.174225352517])] {
            XCTAssertEqual(MedicationLevel.remaining(at: start, doses: [dose], medication: "Semaglutide", halfLifeDays: 7, now: start, model: model), 0)
            for (hours, value) in zip([1, 24, 72, 168, 336], expected) {
                XCTAssertEqual(MedicationLevel.remaining(at: start.addingTimeInterval(Double(hours)*3600), doses: [dose], medication: "Semaglutide", halfLifeDays: 7, now: start, model: model), value, accuracy: 0.000000001)
            }
        }
    }
    func testAbsorptionPlansOnlyAffectFutureAndNeverIncludeSkippedOrOtherMedications() {
        let start = Date(timeIntervalSince1970: 1700000000)
        let planDate = start.addingTimeInterval(48 * 3600)
        let doses = [
            DoseEntry(date: start, medication: "Semaglutide", milligrams: 1),
            DoseEntry(date: planDate, medication: "Semaglutide", milligrams: 0.5, status: .planned),
            DoseEntry(date: start, medication: "Semaglutide", milligrams: 9, status: .skipped),
            DoseEntry(date: start, medication: "Other", milligrams: 9),
            DoseEntry(date: planDate, medication: "Semaglutide", milligrams: 9),
            DoseEntry(date: start.addingTimeInterval(-3600), medication: "Semaglutide", milligrams: 9, status: .planned)
        ]
        let current = start.addingTimeInterval(24 * 3600)
        XCTAssertEqual(MedicationLevel.remaining(at: current, doses: doses, medication: "Semaglutide", halfLifeDays: 7, includePlans: true, now: current, model: .semaglutide), 0.354583889016, accuracy: 1e-9)
        let future = start.addingTimeInterval(72 * 3600)
        XCTAssertEqual(MedicationLevel.remaining(at: future, doses: doses, medication: "Semaglutide", halfLifeDays: 7, includePlans: true, now: current, model: .semaglutide), 0.740380983794, accuracy: 1e-9)
        XCTAssertEqual(MedicationLevel.remaining(at: future, doses: doses, medication: "Semaglutide", halfLifeDays: 7, now: current, model: .semaglutide), 0.563089039286, accuracy: 1e-9)
    }
    func testHalfLifeModelAddsOnlyMatchingTakenDosesAndExplicitFuturePlans() {
        let start = Date(timeIntervalSince1970: 1700000000)
        let doses = [DoseEntry(date: start, medication: "Semaglutide", milligrams: 1),
            DoseEntry(date: start, medication: "Tirzepatide", milligrams: 5),
            DoseEntry(date: start.addingTimeInterval(7 * 86400), medication: "Semaglutide", milligrams: 1, status: .planned)]
        let week = start.addingTimeInterval(7 * 86400)
        XCTAssertEqual(MedicationLevel.remaining(at: week, doses: doses, medication: "Semaglutide", halfLifeDays: 7, now: start), 0.5, accuracy: 0.000001)
        XCTAssertEqual(MedicationLevel.remaining(at: week, doses: doses, medication: "Semaglutide", halfLifeDays: 7, includePlans: true, now: start), 1.5, accuracy: 0.000001)
        XCTAssertEqual(MedicationLevel.remaining(at: start.addingTimeInterval(-1), doses: doses, medication: "Semaglutide", halfLifeDays: 7, now: start), 0)
    }
    func testWeightInputRejectsJunkAndImpossibleValuesAndSupportsLocaleDecimal() {
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(EntryValidation.number("195.5", locale: us), 195.5)
        XCTAssertEqual(EntryValidation.number("88,5", locale: Locale(identifier: "de_DE")), 88.5)
        for input in ["12abc", "NaN", "1e4", "-90", "1,2,3", ""] { XCTAssertNil(EntryValidation.number(input, locale: us)) }
        XCTAssertFalse(EntryValidation.weight(0))
        XCTAssertFalse(EntryValidation.weight(900))
        XCTAssertFalse(EntryValidation.weight(.infinity))
        XCTAssertTrue(EntryValidation.weight(88.5))
    }
    func testGoalPaceUsesFutureDeadlineAndDoesNotInventCalories() {
        let now = Date(timeIntervalSince1970: 1700000000)
        let goal = WeightGoal(kilograms: 80, date: now.addingTimeInterval(10 * 7 * 86400))
        XCTAssertEqual(goal.requiredWeeklyChange(current: 90, now: now), -1)
        XCTAssertNil(WeightGoal(kilograms: 80, date: now).requiredWeeklyChange(current: 90, now: now))
        XCTAssertNil(WeightGoal(kilograms: 80).requiredWeeklyChange(current: 90, now: now))
    }
    func testCheckInRequiresAChosenRatingAndOnlyAcceptsOneThroughFive() {
        XCTAssertFalse(CheckIn(date: Date()).isValid)
        XCTAssertTrue(CheckIn(date: Date(), appetite: 5).isValid)
        XCTAssertTrue(CheckIn(date: Date(), nausea: 1).isValid)
        XCTAssertFalse(CheckIn(date: Date(), appetite: 0, nausea: 1).isValid)
        XCTAssertFalse(CheckIn(date: Date(), nausea: 6).isValid)
    }
}
