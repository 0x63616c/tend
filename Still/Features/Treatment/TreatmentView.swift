import SwiftUI

struct TreatmentView: View {
    @Environment(Store.self) private var store
    @State private var editing = false
    @State private var schedule = false
    @State private var addVial = false
    @State private var selectedVial: Vial?
    var taken: [DoseEntry] { store.journal.doses.filter { $0.medication == store.journal.medication && $0.status == .taken && $0.date <= Date() }.sorted { $0.date > $1.date } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeader("Treatment").padding(.horizontal, 8)
                    Button { editing = true } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "syringe.fill").font(.title2).foregroundStyle(Theme.pine).frame(width: 48, height: 48).background(Theme.sage, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 5) { Text(store.journal.medication).font(.title3.bold()); Text("Treatment details").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }.card()
                    }.buttonStyle(.plain)
                    Button { schedule = true } label: {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Label("Your schedule", systemImage: "calendar").font(.headline); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }
                            HStack(spacing: 0) {
                                ForEach([2,3,4,5,6,7,1], id: \.self) { day in
                                    Text(String(Calendar.current.shortWeekdaySymbols[day-1].prefix(1))).font(.caption.weight(.semibold)).frame(maxWidth: .infinity).frame(height: 36).background(store.journal.schedule.weekdays.contains(day) ? Theme.pine : Color.clear, in: Circle()).foregroundStyle(store.journal.schedule.weekdays.contains(day) ? Theme.background : Color.secondary)
                                }
                            }
                            Label(store.journal.schedule.enabled ? store.reminderStatus : "Reminders off", systemImage: store.journal.schedule.enabled ? "bell" : "bell.slash").font(.caption).foregroundStyle(.secondary)
                        }.card()
                    }.buttonStyle(.plain).accessibilityIdentifier("editSchedule")
                    HStack { Text("Vials").font(.title3.bold()); Spacer(); Button { addVial = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }.accessibilityLabel("Add Vial") }
                    if store.journal.vials.isEmpty { Button("Add your first vial") { addVial = true }.frame(maxWidth: .infinity).card() }
                    ForEach(store.journal.vials.sorted { $0.received > $1.received }) { vial in
                        Button { selectedVial = vial } label: { VialSummary(vial: vial) }.buttonStyle(.plain)
                    }
                    if !taken.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dose history").font(.headline)
                            HStack { LabeledContent("Taken", value: "\(taken.count)"); Spacer(); Text("\(number(taken.reduce(0) { $0 + $1.milligrams }, digits: 2)) mg").font(.caption).foregroundStyle(.secondary) }
                            ForEach(taken.prefix(4)) { dose in
                                HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text(dose.date, format: .dateTime.month(.abbreviated).day()); Spacer(); Text("\(number(dose.milligrams, digits: 3)) mg").monospacedDigit() }.font(.subheadline)
                            }
                        }.card()
                    }
                }.padding(.horizontal, 16).padding(.bottom, 24)
            }.background(Theme.background).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $editing) { TreatmentEditor() }
                .sheet(isPresented: $schedule) { ScheduleEditor() }
                .sheet(isPresented: $addVial) { VialEditor() }
                .sheet(item: $selectedVial) { VialEditor(vial: $0) }
        }
    }
}
