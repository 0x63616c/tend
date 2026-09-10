import SwiftUI

private enum HistoryEntry: Identifiable {
    case weight(WeightEntry), dose(DoseEntry), checkIn(CheckIn)
    var id: UUID { switch self { case .weight(let e): e.id; case .dose(let e): e.id; case .checkIn(let e): e.id } }
    var date: Date { switch self { case .weight(let e): e.date; case .dose(let e): e.date; case .checkIn(let e): e.date } }
    var kind: String { switch self { case .weight: "Weight"; case .dose: "Doses"; case .checkIn: "Check-ins" } }
}

struct JournalView: View {
    @Environment(Store.self) private var store
    @State private var weight: WeightEntry?
    @State private var dose: DoseEntry?
    @State private var checkIn: CheckIn?
    @State private var deleting: HistoryEntry?
    @State private var adding: String?
    @State private var filter = "All"
    private var entries: [HistoryEntry] {
        (store.journal.weights.map(HistoryEntry.weight) + store.journal.doses.map(HistoryEntry.dose) + store.journal.checkIns.map(HistoryEntry.checkIn))
            .filter { filter == "All" || $0.kind == filter }.sorted { $0.date > $1.date }
    }
    private var days: [Date] { Array(Set(entries.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >) }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    FilterBar(selection: $filter, options: ["All", "Doses", "Weight", "Check-ins"].map { ($0, $0) })
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                ForEach(days, id: \.self) { day in
                    Section(day.formatted(date: .abbreviated, time: .omitted)) {
                        ForEach(entries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) { entry in
                            Button { edit(entry) } label: { row(entry) }.buttonStyle(.plain)
                                .swipeActions(allowsFullSwipe: false) { Button("Delete", role: .destructive) { deleting = entry }.tint(.red) }
                        }
                    }
                }
                if entries.isEmpty { ContentUnavailableView("No entries yet", systemImage: "book.closed", description: Text("Your doses, weights and check-ins appear here.")) }
            }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Journal")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu { Button("Weight") { adding = "Weight" }; Button("Dose") { adding = "Dose" }; Button("Check-in") { adding = "Check-in" } } label: { Image(systemName: "plus") }.accessibilityLabel("Add entry")
                    }
                }
                .sheet(isPresented: Binding(get: { adding != nil }, set: { if !$0 { adding = nil } })) {
                    if adding == "Weight" { WeightEditor() } else if adding == "Dose" { DoseEditor() } else { CheckInEditor() }
                }
                .sheet(item: $weight) { WeightEditor(entry: $0) }
                .sheet(item: $dose) { DoseEditor(entry: $0) }
                .sheet(item: $checkIn) { CheckInEditor(entry: $0) }
                .alert("Delete this entry?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                    Button("Delete entry", role: .destructive) {
                        guard let deleting else { return }
                        switch deleting {
                        case .weight(let e): store.delete(weight: e)
                        case .dose(let e): store.delete(dose: e)
                        case .checkIn(let e): var next = store.journal; next.checkIns.removeAll { $0.id == e.id }; _ = store.commit(next)
                        }
                        self.deleting = nil
                    }
                }
        }
    }
    private func edit(_ entry: HistoryEntry) {
        switch entry { case .weight(let e): weight = e; case .dose(let e): dose = e; case .checkIn(let e): checkIn = e }
    }
    private func row(_ entry: HistoryEntry) -> some View {
        HStack(spacing: 14) {
            switch entry {
            case .dose(let e):
                Image(systemName: e.status == .taken ? "checkmark.circle.fill" : e.status == .skipped ? "minus.circle" : "circle.dashed").foregroundStyle(e.status == .taken ? Color.green : Color.secondary).font(.title2)
                details(title: e.status == .skipped ? "Skipped · \(e.medication)" : "\(number(e.milligrams, digits: 3)) mg · \(e.medication)", subtitle: e.status.rawValue.capitalized, note: e.note)
            case .weight(let e):
                Image(systemName: "scalemass.fill").foregroundStyle(Theme.aqua).font(.title2)
                details(title: "\(number(store.journal.unit.display(e.kilograms))) \(store.journal.unit.symbol)", subtitle: e.date > Date() ? "Planned weight" : "Weight", note: e.note)
            case .checkIn(let e):
                Image(systemName: "face.smiling").foregroundStyle(.orange).font(.title2)
                details(title: "Check-in", subtitle: [e.appetite.map { "Appetite \($0)/5" }, e.nausea.map { "Nausea \($0)/5" }].compactMap { $0 }.joined(separator: " · "), note: e.note)
            }
            Spacer(minLength: 4)
            Text(entry.date, format: .dateTime.hour().minute()).font(.caption2).foregroundStyle(.secondary)
        }.padding(.vertical, 8).contentShape(Rectangle())
    }
    private func details(title: String, subtitle: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)

        }
    }
}
struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var schedule = false
    @State private var treatment = false
    @State private var addingVial = false
    @State private var editingVial: Vial?
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Weight unit", selection: Binding(get: { store.journal.unit }, set: { var next = store.journal; next.unit = $0; _ = store.commit(next) })) { ForEach(WeightUnit.allCases, id: \.self) { Text($0.symbol).tag($0) } }
                    Button("Dose entry") { treatment = true }
                    Picker("Appearance", selection: Binding(get: { store.journal.appearance }, set: { var next = store.journal; next.appearance = $0; _ = store.commit(next) })) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") }
                }
                Section {
                    Picker("Decimal places", selection: Binding(get: { store.journal.liveDecimalPlaces }, set: { var next = store.journal; next.liveDecimalPlaces = $0; _ = store.commit(next) })) { ForEach(3...7, id: \.self) { Text("\($0)").tag($0) } }
                } header: { Text("Live estimate") } footer: { Text("Extra digits show the calculation changing, not greater medical accuracy.") }
                Section {
                    NavigationLink { PrivacyView() } label: { Label("Privacy & About", systemImage: "lock.shield") }
                } footer: { Text("Tendr · 1.0").frame(maxWidth: .infinity).padding(.top, 12) }
            }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { dismiss() } }
                .sheet(isPresented: $schedule) { ScheduleEditor() }
                .sheet(isPresented: $treatment) { DosePreferencesEditor() }
                .sheet(isPresented: $addingVial) { VialEditor() }
                .sheet(item: $editingVial) { VialEditor(vial: $0) }
        }
    }
}
struct TreatmentEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var medication = ""
    @State private var halfLife = 7.0
    @State private var model = MedicationModel.halfLife
    @State private var u100 = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Medication name", text: $medication)
                    HStack { Button("Semaglutide") { medication = "Semaglutide"; halfLife = 7; model = .semaglutide }; Spacer(); Button("Tirzepatide") { medication = "Tirzepatide"; halfLife = 5; model = .tirzepatide } }.font(.caption)
                }
                Section("Estimate model") { Picker("Model", selection: $model) { ForEach(MedicationModel.allCases, id: \.self) { Text($0.title).tag($0) } } }
                if model == .halfLife { Section { Stepper("\(number(halfLife)) days", value: $halfLife, in: 0.5...30, step: 0.5) } header: { Text("Model half-life") } footer: { Text("Used only for the estimate graph. Your dose and schedule are set separately.") } }
                Section { Toggle("I use a U-100 syringe", isOn: $u100) } header: { Text("Dose entry") } footer: { Text("U-100 means 100 units per mL. Check the marking on your syringe.") }
            }.navigationTitle("Treatment").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { var next = store.journal; next.medication = medication.trimmingCharacters(in: .whitespacesAndNewlines); next.halfLifeDays = halfLife; next.medicationModel = model; next.syringeUnitsPerML = u100 ? 100 : nil; if store.commit(next) { dismiss() } }.disabled(medication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } }
                .onAppear { medication = store.journal.medication; halfLife = store.journal.halfLifeDays; model = store.journal.resolvedMedicationModel; u100 = store.journal.syringeUnitsPerML == 100 }
        }
    }
}
struct PrivacyView: View {
    var body: some View {
        List {
            Section("On this iPhone") { Text("No account, ads, analytics SDKs, or server. Your journal is stored locally. Device backups follow your iPhone settings.") }
            Section("Your health") { Text("Tendr is a journal, not a dosing guide. Medication graphs are simplified estimates, not measured levels. Follow your prescriber's instructions.") }
            Section("Assistant") { Text("The assistant is a coming-soon preview. No chat service is connected and no journal data is sent to AI.") }
        }.navigationTitle("Privacy & About").navigationBarTitleDisplayMode(.inline)
    }
}
