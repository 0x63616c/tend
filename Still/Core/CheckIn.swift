import Foundation

public struct CheckIn: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var date: Date
    public var appetite: Int?
    public var nausea: Int?
    public var note: String
    public init(date: Date, appetite: Int? = nil, nausea: Int? = nil, note: String = "") { self.date = date; self.appetite = appetite; self.nausea = nausea; self.note = note }
    public var isValid: Bool {
        guard appetite != nil || nausea != nil else { return false }
        return (appetite.map { (1...5).contains($0) } ?? true) && (nausea.map { (1...5).contains($0) } ?? true)
    }
}
