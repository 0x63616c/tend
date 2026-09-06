import Foundation

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg, lb
    public func display(_ kilograms: Double) -> Double { self == .kg ? kilograms : kilograms * 2.2046226218 }
    public func kilograms(_ value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }
}
public struct Journal: Codable, Equatable, Sendable {
    public var version = 1
    public var vials: [Vial] = []
    public var syringeUnitsPerML: Double?
    public var halfLifeDays: Double = 7
    public var appearance = "system"
    public var weights: [WeightEntry] = []
    public var doses: [DoseEntry] = []
    public var medication = "Semaglutide"
    public var concentration: Double?
    public var containerML: Double?
    public var unit: WeightUnit = .lb
    public var schedule = DoseSchedule()
    public init() {}
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
