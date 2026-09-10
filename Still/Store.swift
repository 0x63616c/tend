import SwiftUI
import UserNotifications

@MainActor @Observable final class Store {
    var journal = Journal()
    var error: String?
    var reminderStatus = "Off"
    let demo: Bool
    private var canWrite = true
    private let file: JournalFile
    init() {
        demo = ProcessInfo.processInfo.arguments.contains("--demo")
        let root = URL.applicationSupportDirectory.appendingPathComponent("Still", isDirectory: true)
        file = JournalFile(url: root.appendingPathComponent(ProcessInfo.processInfo.arguments.contains("--uitest") ? "test.json" : "journal.json"))
        if ProcessInfo.processInfo.arguments.contains("--uitest"), ProcessInfo.processInfo.arguments.contains("--reset-test-journal") {
            try? FileManager.default.removeItem(at: file.url)
        }
        if demo { journal = Self.demoJournal() }
        else {
            do { journal = try file.load() } catch { canWrite = false; self.error = "Your journal could not be opened. Please keep the app installed to preserve your data. \(error.localizedDescription)" }
        }
    }
    func commit(_ changed: Journal) -> Bool {
        guard canWrite else { error = "Your existing journal could not be opened. Saving is paused to preserve it."; return false }
        do {
            if !demo { try file.save(changed) }
            journal = changed
            return true
        } catch { self.error = "Could not save. \(error.localizedDescription)"; return false }
    }
    func save(weight: WeightEntry) -> Bool {
        guard EntryValidation.weight(weight.kilograms) else { error = TrackingError.invalidAmount.localizedDescription; return false }
        var next = journal
        next.weights.removeAll { $0.id == weight.id }; next.weights.append(weight)
        return commit(next)
    }
    func save(dose: DoseEntry) -> Bool {
        do { try dose.validate(now: Date()) } catch { self.error = error.localizedDescription; return false }
        var next = journal
        next.doses.removeAll { $0.id == dose.id }; next.doses.append(dose)
        return commit(next)
    }
    @discardableResult func delete(weight: WeightEntry) -> Bool { var next = journal; next.weights.removeAll { $0.id == weight.id }; return commit(next) }
    @discardableResult func delete(dose: DoseEntry) -> Bool { var next = journal; next.doses.removeAll { $0.id == dose.id }; return commit(next) }
    static let reminderTitle = "Time for your check-in"
    static let reminderBody = "Open Tendr to review your schedule and log your dose."
    func sendTestReminder() async -> String {
        let center = UNUserNotificationCenter.current()
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                return "Notifications are off in iPhone Settings."
            }
            let content = UNMutableNotificationContent()
            content.title = Self.reminderTitle
            content.body = Self.reminderBody
            content.sound = .default
            try await center.add(UNNotificationRequest(identifier: "tend-preview", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)))
            return "Leave Tendr to see it in 5 seconds."
        } catch { return "Could not send a test notification. Try again." }
    }
    func syncReminders() async {
        guard !demo else { reminderStatus = "Demo • no notifications"; return }
        let center = UNUserNotificationCenter.current()
        guard journal.schedule.enabled else {
            center.removeAllPendingNotificationRequests(); reminderStatus = "Off"; return
        }
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else { reminderStatus = "Disabled in iPhone Settings"; return }
            center.removeAllPendingNotificationRequests()
            for day in journal.schedule.weekdays.sorted() {
                let content = UNMutableNotificationContent()
                content.title = Self.reminderTitle
                content.body = Self.reminderBody
                content.sound = .default
                let components = DateComponents(hour: journal.schedule.hour, minute: journal.schedule.minute, weekday: day)
                let request = UNNotificationRequest(identifier: "still-weekday-\(day)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
                try await center.add(request)
            }
            reminderStatus = "On · \(journal.schedule.weekdays.count) days a week"
        } catch { reminderStatus = "Could not schedule reminders"; self.error = error.localizedDescription }
    }
    static func demoJournal() -> Journal {
        var journal = Journal(); journal.concentration = 5; journal.containerML = 2
        journal.schedule.weekdays = [2, 5]
        journal.syringeUnitsPerML = 100
        journal.vials = [Vial(received: Date().addingTimeInterval(-21 * 86400), medication: "Semaglutide", concentration: 5, volumeML: 2)]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        journal.schedule.startDate = cal.date(byAdding: .day, value: -4, to: today)!
        let values: [Double] = [94.8,94.5,94.7,94.0,93.7,93.9,93.1,92.8,93.0,92.4,92.2,91.8,92.0,91.4,91.2,91.5,90.8,90.6,90.9,90.2,90.0,89.8,89.9,89.4,89.2,89.4,88.9,88.7,88.5]
        journal.weights = values.enumerated().map { i, value in
            WeightEntry(date: cal.date(byAdding: .day, value: (i - values.count + 1) * 2, to: today)!, kilograms: value, note: i == values.count - 1 ? "Feeling more like myself. A long walk this morning." : "")
        }
        journal.doses = (0..<8).map { i in
            DoseEntry(date: cal.date(byAdding: .day, value: -i * 7 - 2, to: today)!, medication: "Semaglutide", milligrams: 0.5, concentration: 5, note: i == 0 ? "Easy morning. Keeping water close today." : "")
        }
        for i in journal.doses.indices where journal.doses[i].date >= journal.vials[0].received {
            journal.doses[i].vialID = journal.vials[0].id
        }
        journal.checkIns = (0..<7).map { i in
            CheckIn(date: today.addingTimeInterval(Double(-i * 2) * 86400), appetite: [3,2,3,4,3,2,4][i], nausea: [1,1,2,1,2,1,1][i])
        }
        return journal
    }
}
