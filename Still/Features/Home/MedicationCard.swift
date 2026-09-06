import SwiftUI
import Charts

struct MedicationCard: View {
    @Environment(Store.self) private var store
    var expanded = false
    @State private var detail = false
    @State private var selected: Date?
    @State private var info = false
    @State private var showPlans = false
    let now = Date()
    var halfLife: Double { store.journal.halfLifeDays }
    var samples: [LevelSample] {
        (-112...112).map { offset in
            let date = now.addingTimeInterval(Double(offset) * 3 * 3600)
            return LevelSample(date: date, amount: amount(at: date), future: date > now)
        }
    }
    func amount(at date: Date) -> Double {
        MedicationLevel.remaining(at: date, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: halfLife, includePlans: showPlans, now: now)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.journal.medication.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.6).foregroundStyle(Theme.pine)
                    Text("Medication level").font(.headline)
                }
                Spacer()
                Button { info = true } label: { Image(systemName: "info.circle").foregroundStyle(.secondary) }.accessibilityLabel("About medication estimates")
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let timestamp = selected ?? context.date
                let value = MedicationLevel.remaining(at: timestamp, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: halfLife, includePlans: showPlans, now: context.date)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(value.formatted(.number.precision(.fractionLength(selected == nil ? 5 : 3)))).font(.system(size: 38, weight: .semibold, design: .rounded)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                        Text("mg").font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack(spacing: 6) {
                        Circle().fill(selected == nil ? Color.green : Theme.pine).frame(width: 5, height: 5)
                        Text(selected == nil ? "Live model estimate" : "Model estimate").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(timestamp, format: selected == nil ? .dateTime.hour().minute().second() : .dateTime.month(.abbreviated).day().hour().minute()).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
            Chart {
                ForEach(samples.filter { !$0.future }) { point in
                    AreaMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount)).foregroundStyle(LinearGradient(colors: [Theme.pine.opacity(0.20), Theme.pine.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount), series: .value("Series", "History")).foregroundStyle(Theme.pine).lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                ForEach(samples.filter { $0.date >= now }) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount), series: .value("Series", "Projection")).foregroundStyle(Theme.pine.opacity(0.65)).lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                RuleMark(x: .value("Now", now)).foregroundStyle(.secondary.opacity(0.4)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("Date", selected ?? now), y: .value("Estimate", amount(at: selected ?? now))).foregroundStyle(Theme.pine).symbolSize(55)
            }
            .chartXSelection(value: $selected)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.1)); AxisValueLabel() } }
            .frame(height: expanded ? 300 : 145)
            .accessibilityIdentifier(expanded ? "medicationDetailChart" : "medicationChart").contentShape(Rectangle()).simultaneousGesture(TapGesture().onEnded { if !expanded { detail = true } })
            .accessibilityLabel("Estimated medication decay. Solid line shows history; dashed line shows projection.")
            HStack(spacing: 14) {
                Label("\(number(halfLife))d half-life", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { showPlans.toggle() } label: {
                    Label("Plans", systemImage: showPlans ? "checkmark.circle.fill" : "plus.circle").font(.caption.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 6).background(Theme.pine.opacity(0.1), in: Capsule())
                }.accessibilityLabel("Include explicitly planned doses").accessibilityValue(showPlans ? "On" : "Off")
            }
        }.card()
        .sheet(isPresented: $detail) {
            NavigationStack {
                ScrollView { MedicationCard(expanded: true).padding(16) }.background(Theme.background).navigationTitle("Medication").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { detail = false } }
            }
        }
        .sheet(isPresented: $info) {
            NavigationStack {
                List {
                    Section("An estimate, not a measurement") {
                        Text("This graph adds the remaining fraction of each logged dose using a simple half-life model. It is not your measured blood level or the exact amount in your body.")
                        Text("It assumes immediate absorption and does not account for individual clearance, bioavailability, or delayed absorption. Do not use it to choose or change a dose.")
                    }
                    Section("Projection") { Text("The dashed line assumes no further doses unless Plans is on. Plans includes only future doses you explicitly entered. Your weekly schedule does not invent dose amounts.") }
                    Section("Half-life") {
                        Text("Current assumption: \(number(halfLife)) days. Semaglutide labeling describes approximately 1 week; tirzepatide approximately 5 days. You can change the assumption in Settings.")
                        Link("Semaglutide prescribing information", destination: URL(string: "https://www.accessdata.fda.gov/drugsatfda_docs/label/2026/209637s038lbl.pdf")!)
                        Link("Tirzepatide prescribing information", destination: URL(string: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=0818426a-53eb-4db7-9609-bbae1e7a3964")!)
                    }
                }.navigationTitle("About this graph").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { info = false } }
            }
        }
    }
}
struct LevelSample: Identifiable {
    var id: Date { date }
    let date: Date
    let amount: Double
    let future: Bool
}
