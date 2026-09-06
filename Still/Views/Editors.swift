import SwiftUI

struct WeightEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: WeightEntry?
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") { TextField("Weight", text: $amount).keyboardType(.decimalPad).accessibilityIdentifier("weightAmount"); Text(store.journal.unit.rawValue).foregroundStyle(.secondary); DatePicker("Date", selection: $date) }
                if date > Date() { Text("Future entry · excluded from your progress until this date.").font(.caption) }
                Section("Notes") { TextField("How are you feeling?", text: $note, axis: .vertical).lineLimit(3...6) }
            }.navigationTitle(entry == nil ? "Log weight" : "Edit weight").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
                    var updated = WeightEntry(date: date, kilograms: store.journal.unit.kilograms(value), note: note)
                    if let entry { updated.id = entry.id }
                    if store.save(weight: updated) { dismiss() }
                }.disabled(Double(amount.replacingOccurrences(of: ",", with: ".")).map { !$0.isFinite || $0 <= 0 } ?? true) } }
                .onAppear { if let entry { amount = number(store.journal.unit.display(entry.kilograms), digits: 2); date = entry.date; note = entry.note } }
        }
    }
}
struct DoseEditor: View {
    var scheduledDate: Date? = nil
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: DoseEntry?
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var status = DoseEntry.Status.taken
    @State private var mode = "mg"
    @State private var vialID: UUID?
    @State private var confirmedU100 = false
    @State private var addingVial = false
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
                    Picker("Status", selection: $status) { ForEach(DoseEntry.Status.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.segmented)
                    if status != .skipped {
                        VStack(spacing: 16) {
                            Picker("Input unit", selection: $mode) { Text("mg").tag("mg"); Text("mL").tag("mL"); Text("Units").tag("units") }.pickerStyle(.segmented)
                            HStack(alignment: .firstTextBaseline) {
                                TextField("0", text: $amount).keyboardType(.decimalPad).font(.system(size: 54, weight: .medium, design: .rounded)).multilineTextAlignment(.center).accessibilityLabel("Dose amount").accessibilityIdentifier("doseAmount")
                                Text(mode).font(.title3).foregroundStyle(.secondary)
                            }.padding(.vertical, 10)
                            if mode != "mg", let mg = milligrams { Text("\(number(mg, digits: 4)) mg · \(number((parse(amount) ?? 0) / (mode == "units" ? 100 : 1), digits: 4)) mL").font(.subheadline.weight(.medium)).foregroundStyle(.indigo) }
                            if mode == "units" {
                                Toggle("My syringe is U-100", isOn: $confirmedU100).font(.subheadline)
                                Text("100 units = 1 mL").font(.caption).foregroundStyle(.secondary)
                            }
                            if mode != "mg" && concentration == nil { Text("Add a vial with its concentration to log in \(mode).").font(.subheadline).foregroundStyle(.orange) }
                        }.card()
                        if entry == nil {
                            VStack(spacing: 12) {
                                Picker("Vial", selection: $vialID) {
                                    Text("No vial").tag(nil as UUID?)
                                    ForEach(store.journal.vials.sorted { $0.received > $1.received }) { item in Text("\(item.medication) · \(item.received.formatted(date: .abbreviated, time: .omitted))").tag(Optional(item.id)) }
                                }
                                if let concentration { HStack { Text("Concentration"); Spacer(); Text("\(number(concentration, digits: 3)) mg/mL") }.font(.caption).foregroundStyle(.secondary) }
                                Button("Add a vial") { addingVial = true }.font(.subheadline)
                            }.card()
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        DatePicker(status == .planned ? "Planned for" : status == .skipped ? "Skipped date" : "Taken at", selection: $date)
                        Divider()
                        TextField("Add a note…", text: $note, axis: .vertical).lineLimit(2...5)
                    }.card()
                    if let localError { Text(localError).font(.footnote).foregroundStyle(.red) }
                    Button { save() } label: { Text(status == .skipped ? "Mark Skipped" : status == .planned ? "Save Plan" : "Save Dose").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10) }.buttonStyle(.borderedProminent).disabled(milligrams == nil).accessibilityIdentifier("saveDose")
                }.padding(20)
            }.background(Theme.background).navigationTitle(entry == nil ? "Log Dose" : "Edit Dose").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .sheet(isPresented: $addingVial) { VialEditor() }
                .onChange(of: date) { _, date in if date > Date() && status == .taken { status = .planned } }
                .onAppear {
                    confirmedU100 = store.journal.syringeUnitsPerML == 100
                    if let entry {
                        amount = number(entry.syringeUnits ?? entry.milligrams, digits: 4); mode = entry.syringeUnits != nil ? "units" : "mg"
                        confirmedU100 = entry.syringeUnitsPerML == 100 || confirmedU100
                        date = entry.date; status = entry.status; note = entry.note; vialID = entry.vialID
                    } else { vialID = store.journal.vials.sorted { $0.received > $1.received }.first?.id; mode = confirmedU100 && vialID != nil ? "units" : "mg" }
                }
        }
    }
    func save() {
        guard let mg = milligrams else { return }
        var updated = DoseEntry(date: date, scheduledDate: entry?.scheduledDate ?? scheduledDate, medication: entry?.medication ?? vial?.medication ?? store.journal.medication, milligrams: mg, concentration: concentration, status: status, note: note)
        if let entry { updated.id = entry.id }
        updated.vialID = vialID
        if mode == "units" && status != .skipped { updated.syringeUnits = parse(amount); updated.syringeUnitsPerML = 100 }
        if store.save(dose: updated) {
            if confirmedU100 && store.journal.syringeUnitsPerML != 100 { var next = store.journal; next.syringeUnitsPerML = 100; _ = store.commit(next) }
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
                        HStack { Text(Calendar.current.weekdaySymbols[day - 1]).foregroundStyle(.primary); Spacer(); if days.contains(day) { Image(systemName: "checkmark").foregroundStyle(Theme.pine) } }
                    }.accessibilityAddTraits(days.contains(day) ? .isSelected : [])
                } } header: { Text("Days of the week") } footer: { Text("Choose the days in your prescribed schedule. Your actual dose dates can be logged separately.") }
                Section("Reminders") { DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute); Toggle("Remind me", isOn: $reminders) }
                Section("Notification preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Image(systemName: "cross.case.fill").foregroundStyle(.indigo); Text("TEND").font(.caption.weight(.semibold)); Spacer(); Text(time, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary) }
                        Text("Time for your check-in").font(.subheadline.weight(.semibold))
                        Text("Open Tend to review your schedule and log your dose.").font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }
            }.navigationTitle("Your schedule").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    var next = store.journal; next.schedule.weekdays = days; next.schedule.hour = Calendar.current.component(.hour, from: time); next.schedule.minute = Calendar.current.component(.minute, from: time); next.schedule.enabled = reminders
                    if store.commit(next) { Task { await store.syncReminders() }; dismiss() }
                }.disabled(days.isEmpty) } }
                .onAppear { days = store.journal.schedule.weekdays; reminders = store.journal.schedule.enabled; time = Calendar.current.date(bySettingHour: store.journal.schedule.hour, minute: store.journal.schedule.minute, second: 0, of: Date())! }
        }
    }
}
