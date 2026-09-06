import SwiftUI
struct JournalView: View {
    @Environment(Store.self) private var store
    @State private var weight: WeightEntry?
    @State private var dose: DoseEntry?
    @State private var filter = "All"
    var body: some View {
        NavigationStack {
            List {
                Section { Picker("Entries", selection: $filter) { Text("All").tag("All"); Text("Doses").tag("Doses"); Text("Weight").tag("Weight") }.pickerStyle(.segmented).listRowBackground(Color.clear) }
                if filter != "Weight" {
                    Section("Doses") { ForEach(store.journal.doses.sorted { $0.date > $1.date }) { entry in
                        Button { dose = entry } label: {
                            HStack(spacing: 15) {
                                Image(systemName: entry.status == .taken ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(Theme.pine).font(.title2)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(number(entry.milligrams, digits: 3)) mg · \(entry.medication)").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                    Text(entry.date, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                                    if !entry.note.isEmpty { Text(entry.note).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                                }
                                Spacer(); Text(entry.status.rawValue.capitalized).font(.caption2).foregroundStyle(Theme.pine)
                            }.padding(.vertical, 8)
                        }.swipeActions { Button("Delete", role: .destructive) { store.delete(dose: entry) } }
                    } }
                }
                if filter != "Doses" {
                    Section("Weight") { ForEach(store.journal.weights.sorted { $0.date > $1.date }) { entry in
                        Button { weight = entry } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(number(store.journal.unit.display(entry.kilograms))) \(store.journal.unit.rawValue)").font(.headline).foregroundStyle(.primary)
                                    Text(entry.date, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(.secondary)
                                    if !entry.note.isEmpty { Text(entry.note).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                                }; Spacer(); if entry.date > Date() { Text("Future").font(.caption) }; Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }.padding(.vertical, 6)
                        }.swipeActions { Button("Delete", role: .destructive) { store.delete(weight: entry) } }
                    } }
                }
            }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Journal")
                .overlay { if store.journal.weights.isEmpty && store.journal.doses.isEmpty { ContentUnavailableView("Room for your story", systemImage: "book.closed", description: Text("Log a dose or weight from Today.")) } }
                .sheet(item: $weight) { WeightEditor(entry: $0) }.sheet(item: $dose) { DoseEditor(entry: $0) }
        }
    }
}
struct SettingsView: View {
    @Environment(Store.self) private var store
    @State private var schedule = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Your treatment") { LabeledContent("Medication", value: store.journal.medication); if let concentration = store.journal.concentration { LabeledContent("Concentration", value: "\(number(concentration)) mg/mL") }; Button("Schedule & reminders") { schedule = true }; Text(store.reminderStatus).font(.caption).foregroundStyle(.secondary) }
                Section("Preferences") { Picker("Weight unit", selection: Binding(get: { store.journal.unit }, set: { var next = store.journal; next.unit = $0; _ = store.commit(next) })) { ForEach(WeightUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) } } }
                Section("A private space") { Label("No account. No tracking. No ads.", systemImage: "lock.shield"); Text("Your journal stays on this iPhone. Still does not collect or send your health information. Device backups follow your iPhone settings.").font(.footnote).foregroundStyle(.secondary) }
                Section { Text("Still is a personal journal, not a dosing guide. Follow the schedule and dose given by your prescriber.").font(.footnote).foregroundStyle(.secondary) } footer: { Text("STILL · VERSION 1.0\nMade for the everyday.").frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 20) }
            }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Settings").sheet(isPresented: $schedule) { ScheduleEditor() }
        }
    }
}
