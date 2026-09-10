import Foundation

/// An illustrative dose-decay model, not measured blood concentration or a dosing recommendation.
public enum MedicationLevel {
    public static func remaining(at date: Date, doses: [DoseEntry], medication: String, halfLifeDays: Double, includePlans: Bool = false, now: Date, model: MedicationModel = .halfLife) -> Double {
        guard model != .halfLife || (halfLifeDays.isFinite && halfLifeDays > 0) else { return 0 }
        return doses.filter {
            $0.medication.caseInsensitiveCompare(medication) == .orderedSame && $0.date <= date &&
            $0.milligrams.isFinite && $0.milligrams > 0 &&
            (($0.status == .taken && $0.date <= now) || (includePlans && $0.status == .planned && $0.date > now))
        }.reduce(0) { sum, dose in
            sum + dose.milligrams * model.fraction(hours: date.timeIntervalSince(dose.date) / 3600, halfLifeDays: halfLifeDays)
        }
    }
}

/// Reference-population parameters, not personalised pharmacokinetics.
/// See docs/MEDICATION-MODEL.md for sources, equations and limitations.
public enum MedicationModel: String, Codable, CaseIterable, Sendable {
    case semaglutide, tirzepatide, halfLife
    public var title: String {
        switch self { case .semaglutide: "Semaglutide injection"; case .tirzepatide: "Tirzepatide injection"; case .halfLife: "Simple half-life" }
    }
    public static func inferred(from name: String) -> Self {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "semaglutide", "ozempic", "wegovy": .semaglutide
        case "tirzepatide", "mounjaro", "zepbound": .tirzepatide
        default: .halfLife
        }
    }
    func fraction(hours t: Double, halfLifeDays: Double) -> Double {
        guard t.isFinite && t >= 0 else { return 0 }
        if self == .halfLife { return pow(0.5, t / (halfLifeDays * 24)) }
        // ka (/h), CL (L/h), Vc (L), Q (L/h), Vp (L), F (unitless).
        let (ka, cl, vc, q, vp, f): (Double, Double, Double, Double, Double, Double) = self == .semaglutide
            ? (0.0253, 0.0348, 3.59, 0.304, 4.10, 0.847) // Overgaard 2019, Table 4.
            : (0.0373, 0.0329, 2.47, 0.126, 3.98, 0.8) // Schneck 2024, Table 3 reference F.
        let k10 = cl / vc, k12 = q / vc, k21 = q / vp
        let sum = k10 + k12 + k21
        let root = sqrt(sum * sum - 4 * k10 * k21)
        let alpha = (sum + root) / 2, beta = (sum - root) / 2
        // Analytic convolution of absorption with the two disposition exponentials.
        // Fixed profiles have distinct rates; expm1 avoids cancellation near injection time.
        func integral(_ rate: Double) -> Double {
            let slow = min(rate, ka), delta = abs(ka - rate)
            return exp(-slow * t) * (-expm1(-delta * t)) / delta
        }
        let a = integral(alpha), b = integral(beta)
        let central = ((alpha - k21) * a + (k21 - beta) * b) / root
        let peripheral = k12 * (b - a) / root
        return max(0, min(f, f * ka * (central + peripheral)))
    }
}
