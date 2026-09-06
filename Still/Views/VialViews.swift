import SwiftUI

struct VialSummary: View {
    @Environment(Store.self) private var store
    var vial: Vial
    var used: Double { store.journal.doses.filter { $0.vialID == vial.id && $0.status == .taken && $0.date <= Date() }.reduce(0) { $0 + $1.milligrams / ($1.concentration ?? vial.concentration) } }
    var remaining: Double { max(0, vial.volumeML - used) }
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6).fill(.blue.opacity(0.08))
                RoundedRectangle(cornerRadius: 5).fill(.blue.opacity(0.5)).frame(height: 40 * max(0, min(1, remaining / vial.volumeML)))
            }.frame(width: 25, height: 44).overlay(RoundedRectangle(cornerRadius: 6).stroke(.blue.opacity(0.3), lineWidth: 1))
            VStack(alignment: .leading, spacing: 4) {
                Text("Current vial").font(.subheadline.weight(.semibold))
                Text("\(number(remaining, digits: 2)) of \(number(vial.volumeML)) mL remaining").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(number(vial.concentration))\nmg/mL").font(.caption.weight(.medium)).multilineTextAlignment(.trailing).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).card()
        .accessibilityElement(children: .combine)
    }
}
struct VialEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var vial: Vial?
    @State private var medication = ""
    @State private var received = Date()
    @State private var concentration = ""
    @State private var volume = ""
    @State private var note = ""
    var valid: Bool { parse(concentration).map { $0 > 0 && $0.isFinite } == true && parse(volume).map { $0 > 0 && $0.isFinite } == true && !medication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var body: some View {
        NavigationStack {
            Form {
                Section("Vial details") {
                    TextField("Medication", text: $medication)
                    DatePicker("Received", selection: $received, displayedComponents: .date)
                    HStack { TextField("Concentration", text: $concentration).keyboardType(.decimalPad); Text("mg/mL").foregroundStyle(.secondary) }
                    HStack { TextField("Starting volume", text: $volume).keyboardType(.decimalPad); Text("mL").foregroundStyle(.secondary) }
                    if let c = parse(concentration), let v = parse(volume), valid { LabeledContent("Total medication", value: "\(number(c * v, digits: 2)) mg") }
                }
                Section("Notes") { TextField("Optional note", text: $note, axis: .vertical).lineLimit(3...5) }
            }.navigationTitle(vial == nil ? "Add Vial" : "Edit Vial").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        guard let c = parse(concentration), let v = parse(volume), valid else { return }
                        var updated = Vial(received: received, medication: medication, concentration: c, volumeML: v, note: note)
                        if let vial { updated.id = vial.id }
                        var journal = store.journal
                        journal.vials.removeAll { $0.id == updated.id }; journal.vials.append(updated)
                        if store.commit(journal) { dismiss() }
                    }.disabled(!valid) }
                }
                .onAppear { medication = vial?.medication ?? store.journal.medication; if let vial { received = vial.received; concentration = number(vial.concentration, digits: 4); volume = number(vial.volumeML, digits: 3); note = vial.note } }
        }
    }
}
func parse(_ string: String) -> Double? {
    let formatter = NumberFormatter(); formatter.locale = .current; formatter.numberStyle = .decimal
    return formatter.number(from: string)?.doubleValue
}
