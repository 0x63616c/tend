import SwiftUI
import Charts

struct MedicationCard: View {
    @Environment(Store.self) private var store
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
                Label("Medication level", systemImage: "waveform.path.ecg").font(.subheadline.weight(.semibold)).foregroundStyle(.indigo)
                Spacer()
                Button { info = true } label: { Image(systemName: "info.circle").foregroundStyle(.secondary) }.accessibilityLabel("About medication estimates")
            }
            HStack(alignment: .lastTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(number(amount(at: selected ?? now), digits: 2)).font(.system(size: 38, weight: .bold, design: .rounded)).contentTransition(.numericText())
                    Text("mg").font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(selected == nil ? "Estimated now" : "Estimate").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    if let selected { Text(selected, format: .dateTime.month(.abbreviated).day().hour()).font(.caption2).foregroundStyle(.secondary) }
                    else { Text(store.journal.medication).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Chart {
                ForEach(samples.filter { !$0.future }) { point in
                    AreaMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount)).foregroundStyle(LinearGradient(colors: [.indigo.opacity(0.20), .indigo.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount), series: .value("Series", "History")).foregroundStyle(.indigo).lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                ForEach(samples.filter { $0.date >= now }) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Estimated mg", point.amount), series: .value("Series", "Projection")).foregroundStyle(.indigo.opacity(0.65)).lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                RuleMark(x: .value("Now", now)).foregroundStyle(.secondary.opacity(0.4)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("Date", selected ?? now), y: .value("Estimate", amount(at: selected ?? now))).foregroundStyle(.indigo).symbolSize(55)
            }
            .chartXSelection(value: $selected)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.1)); AxisValueLabel() } }
            .frame(height: 145)
            .accessibilityLabel("Estimated medication decay. Solid line shows history; dashed line shows projection.")
            HStack(spacing: 14) {
                Label("\(number(halfLife))d half-life", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Toggle("Plans", isOn: $showPlans).font(.caption).fixedSize().controlSize(.mini).accessibilityLabel("Include explicitly planned doses")
            }
        }.card()
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
