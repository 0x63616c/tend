import Foundation

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg, lb
    public var symbol: String { self == .lb ? "lbs" : "kg" }
    public func display(_ kilograms: Double) -> Double { self == .kg ? kilograms : kilograms * 2.2046226218 }
    public func kilograms(_ value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }
}
public struct Journal: Codable, Equatable, Sendable {
    public var version = 1
    public var goal: WeightGoal?
    public var vials: [Vial] = []
    public var doseInputUnit: String?
    public var syringeUnitsPerML: Double?
    public var halfLifeDays: Double = 7
    public var medicationModel: MedicationModel?
    public var resolvedMedicationModel: MedicationModel { medicationModel ?? MedicationModel.inferred(from: medication) }
    public var appearance = "system"
    public var healthKitWeightsEnabled = false
    public var weightsStartAtFirstDose = false
    public var weights: [WeightEntry] = []
    public var doses: [DoseEntry] = []
    public var medication = "Semaglutide"
    public var concentration: Double?
    public var containerML: Double?
    public var unit: WeightUnit = .lb
    public var schedule = DoseSchedule()
    public init() {}
    private enum CodingKeys: String, CodingKey { case medicationModel, doseInputUnit, version, goal, vials, syringeUnitsPerML, halfLifeDays, appearance, healthKitWeightsEnabled, weightsStartAtFirstDose, weights, doses, medication, concentration, containerML, unit, schedule }
    public init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version == 1 else { throw TrackingError.invalidFile }
        medicationModel = try values.decodeIfPresent(MedicationModel.self, forKey: .medicationModel)
        doseInputUnit = try values.decodeIfPresent(String.self, forKey: .doseInputUnit)
        if let value = try values.decodeIfPresent(WeightGoal.self, forKey: .goal) { goal = value }
        if let value = try values.decodeIfPresent([Vial].self, forKey: .vials) { vials = value }
        if let value = try values.decodeIfPresent(Double.self, forKey: .syringeUnitsPerML) { syringeUnitsPerML = value }
        if let value = try values.decodeIfPresent(Double.self, forKey: .halfLifeDays) { halfLifeDays = value }
        if let value = try values.decodeIfPresent(String.self, forKey: .appearance) { appearance = value }
        healthKitWeightsEnabled = try values.decodeIfPresent(Bool.self, forKey: .healthKitWeightsEnabled) ?? false
        weightsStartAtFirstDose = try values.decodeIfPresent(Bool.self, forKey: .weightsStartAtFirstDose) ?? false
        if let value = try values.decodeIfPresent([WeightEntry].self, forKey: .weights) { weights = value }
        if let value = try values.decodeIfPresent([DoseEntry].self, forKey: .doses) { doses = value }
        if let value = try values.decodeIfPresent(String.self, forKey: .medication) { medication = value }
        if let value = try values.decodeIfPresent(Double.self, forKey: .concentration) { concentration = value }
        if let value = try values.decodeIfPresent(Double.self, forKey: .containerML) { containerML = value }
        if let value = try values.decodeIfPresent(WeightUnit.self, forKey: .unit) { unit = value }
        if let value = try values.decodeIfPresent(DoseSchedule.self, forKey: .schedule) { schedule = value }
    }

    public var firstTakenDoseDate: Date? {
        doses.lazy.filter { $0.status == .taken }.map(\.date).min()
    }

    public mutating func applyWeightHistoryStart() {
        guard weightsStartAtFirstDose, let firstTakenDoseDate else { return }
        weights.removeAll { $0.date < firstTakenDoseDate }
    }
}
public struct JournalFile {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func save(_ journal: Journal) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(journal)
        try data.write(to: url, options: .atomic)
    }
    public func load() throws -> Journal {
        guard FileManager.default.fileExists(atPath: url.path) else { return Journal() }
        return try JSONDecoder().decode(Journal.self, from: Data(contentsOf: url))
    }
}
