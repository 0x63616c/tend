import Foundation

/// An illustrative dose-decay model, not measured blood concentration or a dosing recommendation.
public enum MedicationLevel {
    public static func remaining(at date: Date, doses: [DoseEntry], medication: String, halfLifeDays: Double, includePlans: Bool = false, now: Date) -> Double {
        guard halfLifeDays.isFinite && halfLifeDays > 0 else { return 0 }
        return doses.filter {
            $0.medication.caseInsensitiveCompare(medication) == .orderedSame && $0.date <= date &&
            $0.milligrams.isFinite && $0.milligrams > 0 &&
            (($0.status == .taken && $0.date <= now) || (includePlans && $0.status == .planned && $0.date > now))
        }.reduce(0) { sum, dose in
            sum + dose.milligrams * pow(0.5, date.timeIntervalSince(dose.date) / (halfLifeDays * 86400))
        }
    }
}
