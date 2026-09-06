import Foundation

public struct WeightEntry: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var date: Date
    public var kilograms: Double
    public var note: String
    public init(date: Date, kilograms: Double, note: String = "") {
        self.date = date; self.kilograms = kilograms; self.note = note
    }
}

public struct WeightSummary {
    public var latest: Double?
    public var lost: Double?
    public var weeklyChange: Double?
    public init(entries: [WeightEntry], now: Date) {
        let actual = entries.filter { $0.date <= now && $0.kilograms.isFinite && $0.kilograms > 0 }.sorted { $0.date < $1.date }
        guard let first = actual.first, let last = actual.last else { return }
        latest = last.kilograms
        lost = first.kilograms - last.kilograms
        let weeks = last.date.timeIntervalSince(first.date) / (7 * 86400)
        weeklyChange = weeks > 0 ? (last.kilograms - first.kilograms) / weeks : nil
    }
}

public struct DoseEntry: Codable, Identifiable, Equatable, Sendable {
    public enum Status: String, Codable, CaseIterable, Sendable { case planned, taken, skipped }
    public var id = UUID()
    public var date: Date
    public var vialID: UUID?
    public var syringeUnits: Double?
    public var syringeUnitsPerML: Double?
    public var scheduledDate: Date?
    public var medication: String
    public var milligrams: Double
    public var concentration: Double?
    public var status: Status
    public var note: String
    public init(date: Date, scheduledDate: Date? = nil, medication: String, milligrams: Double, concentration: Double? = nil, status: Status = .taken, note: String = "") {
        self.date = date; self.scheduledDate = scheduledDate; self.medication = medication
        self.milligrams = milligrams; self.concentration = concentration; self.status = status; self.note = note
    }
    public func validate(now: Date) throws {
        guard milligrams.isFinite && (status == .skipped ? milligrams >= 0 : milligrams > 0),
              concentration.map({ $0.isFinite && $0 > 0 }) ?? true,
              !medication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TrackingError.invalidAmount }
        if status == .taken && date > now { throw TrackingError.futureTaken }
    }
}
public enum TrackingError: LocalizedError {
    case invalidAmount, futureTaken, invalidSchedule, invalidFile
    public var errorDescription: String? {
        switch self {
        case .invalidAmount: "Enter a positive, finite amount."
        case .futureTaken: "A future dose must be planned, not marked taken."
        case .invalidSchedule: "Choose at least one weekday and a valid reminder time."
        case .invalidFile: "This file is not a valid Still backup. Your current data has not changed."
        }
    }
}

public struct DoseSchedule: Codable, Equatable, Sendable {
    public var weekdays: Set<Int> = [2]
    public var startDate = Date()
    public var hour = 9
    public var minute = 0
    public var enabled = false
    public init() {}
    public func occurrences(after date: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        guard count > 0, !weekdays.isEmpty, weekdays.allSatisfy({ (1...7).contains($0) }), (0...23).contains(hour), (0...59).contains(minute) else { return [] }
        var result: [Date] = []
        var cursor = date
        for _ in 0..<min(count, 1000) {
            let next = weekdays.compactMap { weekday in
                calendar.nextDate(after: cursor, matching: DateComponents(hour: hour, minute: minute, weekday: weekday), matchingPolicy: .nextTime, repeatedTimePolicy: .first)
            }.min()
            guard let next else { break }
            result.append(next); cursor = next
        }
        return result
    }
}

public extension DoseSchedule {
    func outstanding(asOf now: Date, doses: [DoseEntry], calendar: Calendar = .current) -> [Date] {
        guard startDate <= now else { return [] }
        var pending: [Date] = []
        var cursor = startDate.addingTimeInterval(-1)
        while let next = occurrences(after: cursor, count: 1, calendar: calendar).first, next <= now {
            let resolved = doses.contains { dose in
                dose.status != .planned && (dose.scheduledDate == next || (dose.scheduledDate == nil && calendar.isDate(dose.date, inSameDayAs: next)))
            }
            if !resolved { pending.append(next) }
            cursor = next
        }
        return pending
    }
}
