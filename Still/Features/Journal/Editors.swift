import SwiftUI

struct WeightEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: WeightEntry?
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var unit: WeightUnit = .lb
    @State private var localError: String?
    var kilograms: Double? { parse(amount).map { unit.kilograms($0) } }
    var valid: Bool { kilograms.map(EntryValidation.weight) ?? false }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(spacing: 18) {
                        Image(systemName: "scalemass.fill").font(.title).foregroundStyle(Theme.aqua)
                        TextField("0.0", text: $amount).keyboardType(.decimalPad).font(.system(size: 62, weight: .medium, design: .rounded)).multilineTextAlignment(.center).accessibilityLabel("Weight").accessibilityIdentifier("weightAmount")
                        Text(unit.symbol).font(.subheadline).foregroundStyle(.secondary)
                        if !amount.isEmpty && !valid { Text("Enter \(number(unit.display(20)))–\(number(unit.display(500))) \(unit.symbol).").font(.caption).foregroundStyle(.orange) }
                    }.card()
                    VStack(alignment: .leading, spacing: 16) {
                        DatePicker("Date", selection: $date)
                        if date > Date() { Label("Future entry · excluded from current trends", systemImage: "calendar").font(.caption).foregroundStyle(.secondary) }
                        DisclosureGroup("Note") { TextField("Add a note…", text: $note, axis: .vertical).lineLimit(2...5) }
                    }.card()
                    if let localError { Text(localError).font(.footnote).foregroundStyle(.red) }
                    Button {
                        guard let kilograms, valid else { return }
                        var updated = WeightEntry(date: date, kilograms: kilograms, note: note)
                        if let entry { updated.id = entry.id }
                        if store.save(weight: updated) { dismiss() } else { localError = store.error; store.error = nil }
                    } label: { Text("Save Weight").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10) }.buttonStyle(.borderedProminent).disabled(!valid).accessibilityIdentifier("saveWeight")
                }.padding(20)
            }.background(Theme.background).navigationTitle(entry == nil ? "Add Weight" : "Edit Weight").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    if let entry { ToolbarItem(placement: .topBarTrailing) { DeleteEntryButton { store.delete(weight: entry) } } }
                }
                .onAppear { unit = store.journal.unit; if let entry { amount = unit.display(entry.kilograms).formatted(.number.grouping(.never).precision(.fractionLength(0...8))); date = entry.date; note = entry.note } }
        }
    }
}
struct DoseEditor: View {
    var scheduledDate: Date? = nil
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: DoseEntry?
    @State private var amount = ""
    @State private var initialized = false
    @State private var date = Date()
    @State private var note = ""
    @State private var status = DoseEntry.Status.taken
    @State private var mode = "mg"
    @State private var vialID: UUID?
    @State private var confirmedU100 = false
    @State private var addingVial = false
    @State private var preferences = false
    @State private var localError: String?
    var vial: Vial? { store.journal.vials.first { $0.id == vialID } }
    var concentration: Double? { entry != nil ? entry?.concentration : vial?.concentration ?? store.journal.concentration }
    var milligrams: Double? {
        if status == .skipped { return 0 }
        guard let value = parse(amount), value.isFinite, value > 0 else { return nil }
        switch mode {
        case "units": guard confirmedU100, let concentration else { return nil }; return value / 100 * concentration
        case "mL": guard let concentration else { return nil }; return value * concentration
        default: return value
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { Image(systemName: "syringe.fill").foregroundStyle(.indigo); Text(entry?.medication ?? vial?.medication ?? store.journal.medication).font(.headline); Spacer() }
                    if let intended = entry?.scheduledDate ?? scheduledDate {
                        Label { Text(intended, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()) } icon: { Image(systemName: "calendar") }.font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack { Text("Status").foregroundStyle(.secondary); Spacer(); Picker("Status", selection: $status) { ForEach(DoseEntry.Status.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.menu).accessibilityIdentifier("doseStatus") }
                    if status != .skipped {
                        VStack(spacing: 16) {
                            Picker("Input unit", selection: Binding(get: { mode }, set: { changeMode($0) })) { Text("mg").tag("mg"); Text("mL").tag("mL"); Text("Units").tag("units") }.pickerStyle(.segmented)
                            ZStack(alignment: .trailing) {
                                TextField("0", text: $amount).keyboardType(.decimalPad).font(.system(size: 54, weight: .medium, design: .rounded)).multilineTextAlignment(.center).accessibilityLabel("Dose amount").accessibilityIdentifier("doseAmount")
                                Text(mode).font(.title3).foregroundStyle(.secondary)
                            }.padding(.vertical, 10)
                            if mode != "mg", let mg = milligrams { Text("\(number(mg, digits: 4)) mg · \(number((parse(amount) ?? 0) / (mode == "units" ? 100 : 1), digits: 4)) mL").font(.subheadline.weight(.medium)).foregroundStyle(.indigo) }
                            if mode == "units" {
                                if store.journal.syringeUnitsPerML == 100 { Text("U-100 · 100 units = 1 mL").font(.caption).foregroundStyle(.secondary) }
                                else { Button("Set up your syringe") { preferences = true }.font(.subheadline) }
                            }
                            if mode != "mg" && concentration == nil { Text("Add a vial with its concentration to log in \(mode).").font(.subheadline).foregroundStyle(.orange) }
                        }.card()
                        if entry == nil {
                            VStack(spacing: 12) {
                                HStack {
                                    if let vial { VialGlyph(fraction: max(0, vial.volumeML - store.journal.doses.filter { $0.vialID == vial.id && $0.status == .taken && $0.date <= Date() }.reduce(0) { $0 + $1.milligrams / ($1.concentration ?? vial.concentration) }) / vial.volumeML) }
                                Picker("Vial", selection: $vialID) {
                                    Text("No vial").tag(nil as UUID?)
                                    ForEach(store.journal.vials.sorted { $0.received > $1.received }) { item in Text("\(item.medication) · \(item.received.formatted(date: .abbreviated, time: .omitted))").tag(Optional(item.id)) }
                                }
                                }
                                if let concentration { HStack { Text("Concentration"); Spacer(); Text("\(number(concentration, digits: 3)) mg/mL") }.font(.caption).foregroundStyle(.secondary) }
                                Button { addingVial = true } label: { Label("Add a vial", systemImage: "plus") }.buttonStyle(.bordered).font(.subheadline)
                            }.card()
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        DatePicker(status == .planned ? "Planned for" : status == .skipped ? "Skipped date" : "Taken at", selection: $date)
                        DisclosureGroup("Note") { TextField("Add a note…", text: $note, axis: .vertical).lineLimit(2...5) }
                    }.card()
                    if let localError { Text(localError).font(.footnote).foregroundStyle(.red) }

                }.padding(20)
            }.safeAreaInset(edge: .bottom) {
                Button { save() } label: { Text(status == .skipped ? "Mark Skipped" : status == .planned ? "Save Plan" : "Save Dose").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 9) }.buttonStyle(.borderedProminent).disabled(milligrams == nil).accessibilityIdentifier("saveDose").padding(.horizontal, 20).padding(.vertical, 10).background(.bar)
            }.background(Theme.background).navigationTitle(entry == nil ? "Log Dose" : "Edit Dose").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    if let entry { ToolbarItem(placement: .topBarTrailing) { DeleteEntryButton { store.delete(dose: entry) } } }
                }
                .sheet(isPresented: $addingVial) { VialEditor() }
                .sheet(isPresented: $preferences, onDismiss: { confirmedU100 = store.journal.syringeUnitsPerML == 100 }) { DosePreferencesEditor() }
                .onChange(of: date) { _, date in if date > Date() && status == .taken { status = .planned } }
                .onAppear {
                    guard !initialized else { return }; initialized = true
                    confirmedU100 = store.journal.syringeUnitsPerML == 100
                    if let entry {
                        amount = number(entry.syringeUnits ?? entry.milligrams, digits: 4); mode = entry.syringeUnits != nil ? "units" : "mg"
                        confirmedU100 = entry.syringeUnitsPerML == 100 || confirmedU100
                        date = entry.date; status = entry.status; note = entry.note; vialID = entry.vialID
                    } else { vialID = store.journal.vials.sorted { $0.received > $1.received }.first?.id; mode = store.journal.doseInputUnit ?? (confirmedU100 && vialID != nil ? "units" : "mg") }
                }
        }
    }
    func changeMode(_ newMode: String) {
        let original = milligrams
        mode = newMode
        guard let original else { amount = ""; return }
        let converted: Double
        switch newMode {
        case "mL":
            guard let concentration, concentration > 0 else { amount = ""; return }
            converted = original / concentration
        case "units":
            guard confirmedU100, let concentration, concentration > 0 else { amount = ""; return }
            converted = original / concentration * 100
        default: converted = original
        }
        amount = converted.formatted(.number.grouping(.never).precision(.fractionLength(0...8)))
    }
    func save() {
        guard let mg = milligrams else { return }
        var updated = DoseEntry(date: date, scheduledDate: entry?.scheduledDate ?? scheduledDate, medication: entry?.medication ?? vial?.medication ?? store.journal.medication, milligrams: mg, concentration: concentration, status: status, note: note)
        if let entry { updated.id = entry.id }
        updated.vialID = vialID
        if mode == "units" && status != .skipped { updated.syringeUnits = parse(amount); updated.syringeUnitsPerML = 100 }
        if store.save(dose: updated, inputUnit: entry == nil && status != .skipped ? mode : nil) {
            dismiss()
        } else { localError = store.error; store.error = nil }
    }
}
struct ScheduleEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var days: Set<Int> = []
    @State private var time = Date()
    @State private var reminders = false
    var body: some View {
        NavigationStack {
            Form {
                Section { ForEach(1...7, id: \.self) { day in
                    Button { if days.contains(day) { days.remove(day) } else { days.insert(day) } } label: {
                        HStack { Text(Calendar.current.weekdaySymbols[day - 1]).foregroundStyle(.primary); Spacer(); if days.contains(day) { Image(systemName: "checkmark").foregroundStyle(.green) } }
                    }.accessibilityAddTraits(days.contains(day) ? .isSelected : [])
                } } header: { Text("Days of the week") } footer: { Text("Choose the days in your prescribed schedule. Your actual dose dates can be logged separately.") }
                Section("Reminders") { Toggle("Remind me", isOn: $reminders); if reminders { DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute) } }
            }.navigationTitle("Your schedule").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    var next = store.journal; next.schedule.weekdays = days; next.schedule.hour = Calendar.current.component(.hour, from: time); next.schedule.minute = Calendar.current.component(.minute, from: time); next.schedule.enabled = reminders
                    if store.commit(next) { Task { await store.syncReminders() }; dismiss() }
                }.disabled(days.isEmpty) } }
                .onAppear { days = store.journal.schedule.weekdays; reminders = store.journal.schedule.enabled; time = Calendar.current.date(bySettingHour: store.journal.schedule.hour, minute: store.journal.schedule.minute, second: 0, of: Date())! }
        }
    }
}

struct DeleteEntryButton: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false
    let delete: () -> Bool
    var body: some View {
        Button(role: .destructive) { confirming = true } label: { Image(systemName: "trash") }
            .accessibilityLabel("Delete entry")
            .alert("Delete this entry?", isPresented: $confirming) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { if delete() { dismiss() } }
            } message: { Text("This cannot be undone.") }
    }
}

struct DosePreferencesEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var unit = "mg"
    @State private var u100 = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferred unit") {
                    Picker("Input unit", selection: $unit) { Text("mg").tag("mg"); Text("mL").tag("mL"); Text("Units").tag("units") }.pickerStyle(.segmented)
                }
                Section {
                    Toggle("I use a U-100 syringe", isOn: $u100)
                } header: { Text("Syringe") } footer: { Text("Check your syringe marking. U-100 means 100 units per mL.") }
            }.navigationTitle("Dose entry").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        var next = store.journal; next.doseInputUnit = unit; next.syringeUnitsPerML = u100 ? 100 : nil
                        if store.commit(next) { dismiss() }
                    } }
                }
                .onAppear { u100 = store.journal.syringeUnitsPerML == 100; unit = store.journal.doseInputUnit ?? (u100 ? "units" : "mg") }
        }
    }
}
