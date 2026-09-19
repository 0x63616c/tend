import SwiftUI
import Charts

struct MedicationCard: View {
    @Environment(Store.self) private var store
    var expanded = false
    @State private var detail = false
    @State private var selected: Date?
    @State private var info = false
    @State private var now = Date()
    var model: MedicationModel { store.journal.resolvedMedicationModel }
    var halfLife: Double { store.journal.halfLifeDays }
    var chartStart: Date { store.firstDoseDate ?? now }
    var chartEnd: Date { now.addingTimeInterval(14 * 86400) }
    /// Recorded doses plus the doses the schedule implies, so the projection shows what is coming.
    var projected: [DoseEntry] { store.journal.scheduledProjection(from: now, through: chartEnd) }
    var chartDoses: [DoseEntry] { store.journal.doses + projected }
    var samples: [LevelSample] {
        let count = expanded ? 720 : 360
        let span = max(1, chartEnd.timeIntervalSince(chartStart))
        return (0...count).map { offset in
            let date = chartStart.addingTimeInterval(span * Double(offset) / Double(count))
            return LevelSample(date: date, amount: amount(at: date), future: date > now)
        }
    }
    func amount(at date: Date) -> Double {
        MedicationLevel.remaining(at: date, doses: chartDoses, medication: store.journal.medication, halfLifeDays: halfLife, includePlans: true, now: now, model: model)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.journal.medication.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.6).foregroundStyle(Theme.pine)
                    Text("Medication level").font(.headline)
                }
                Spacer()
                Button { info = true } label: { Image(systemName: "info.circle").foregroundStyle(.secondary) }.accessibilityLabel("About medication estimates")
            }
            // Recalculate against real time at 60 Hz so high-precision digits do not jump in one-second batches.
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: selected != nil)) { context in
                let timestamp = selected ?? context.date
                let value = MedicationLevel.remaining(at: timestamp, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: halfLife, includePlans: true, now: context.date, model: model)
                let slope = MedicationLevel.rate(at: timestamp, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: halfLife, includePlans: true, now: context.date, model: model)
                let reference = max(value, (store.journal.doses.filter { $0.medication.caseInsensitiveCompare(store.journal.medication) == .orderedSame && $0.status == .taken && $0.date <= context.date }.map(\.milligrams).max() ?? 0) * 0.1)
                let trend = MedicationLevel.trend(rate: slope, reference: reference)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value.formatted(.number.precision(.fractionLength(7)))).font(.system(size: 38, weight: .semibold, design: .rounded)).monospacedDigit().accessibilityIdentifier("liveMedicationAmount").minimumScaleFactor(0.6).lineLimit(1)
                    Text("mg").font(.headline).foregroundStyle(.secondary)
                    if trend != 0 {
                        HStack(spacing: 1) {
                            ForEach(0..<abs(trend), id: \.self) { _ in
                                Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                            }
                        }.font(.caption.bold()).foregroundStyle(.secondary)
                            .accessibilityLabel("Medication level " + (abs(trend) == 2 ? "quickly " : "") + (trend > 0 ? "rising" : "falling"))
                            .accessibilityIdentifier("medicationTrendIndicator")
                    }
                    Spacer()
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
                ForEach(chartDoses.filter { $0.status == .planned && $0.date > now && $0.date <= chartEnd }) { dose in
                    PointMark(x: .value("Date", dose.date), y: .value("Estimated mg", amount(at: dose.date)))
                        .foregroundStyle(Theme.pine.opacity(0.55)).symbolSize(28).symbol(.circle)
                }
                RuleMark(x: .value("Now", now)).foregroundStyle(.secondary.opacity(0.4)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("Date", selected ?? now), y: .value("Estimate", amount(at: selected ?? now))).foregroundStyle(Theme.pine).symbolSize(55)
            }
            .chartXSelection(value: Binding(get: { expanded ? selected : nil }, set: { if expanded { selected = $0 } }))
            .chartXScale(domain: chartStart...chartEnd)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.1)); AxisValueLabel() } }
            .frame(height: expanded ? 300 : 145)
            .accessibilityIdentifier(expanded ? "medicationDetailChart" : "medicationChart")
            .accessibilityLabel("Estimated medication level. Solid line shows history; dashed line shows projection.")
            if !expanded, !projected.isEmpty {
                Text("Dashed line includes \(projected.count) scheduled dose\(projected.count == 1 ? "" : "s") at your usual amount.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.card()
        // The whole card is the tap target; the info button and chart selection still take their own taps first.
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { if !expanded { detail = true } })
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(expanded ? [] : .isButton)
        .accessibilityAction(named: "View details") { if !expanded { detail = true } }
        .accessibilityIdentifier(expanded ? "medicationDetailCard" : "medicationCard")
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        .navigationDestination(isPresented: $detail) {
            ScrollView {
                VStack(spacing: 16) {
                    MedicationCard(expanded: true)
                    MedicationAnalytics()
                }.padding(16)
            }.background(Theme.background)
                .navigationTitle("Medication").navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $info) {
            NavigationStack {
                List {
                    Section("An estimate, not a measurement") {
                        Text("This graph estimates absorbed medication remaining from your recorded doses. It is not a measured blood level or the exact amount in your body.")
                        Text("Injection models include gradual absorption, distribution and clearance using published reference parameters. They are not personalised to your body or vial formulation. Extra decimal places do not add medical accuracy. Do not use the graph to choose or change a dose.")
                    }
                    Section("Projection") { Text("The dashed line includes future doses you explicitly entered and, when you have a schedule, the dates it implies. Scheduled doses are drawn at the average of your last three recorded doses, are never counted as already taken, and are not added to your journal. Log each dose as you take it.") }
                    Section("Model") {
                        Text(model.title)
                        if model == .halfLife { Text("Immediate absorption with a \(number(halfLife))-day half-life. Choose an injection model in Treatment details to include absorption.") }
                        else { Text("Two compartments with first-order absorption and elimination. The displayed mg excludes medication still at the injection site. Reference profiles are fixed; individual weight, health, injection site and formulation can change the real curve.") }
                        Link("Semaglutide model · Overgaard 2019", destination: URL(string: "https://doi.org/10.1007/s13300-019-0581-y")!)
                        Link("Tirzepatide model · Schneck 2024", destination: URL(string: "https://doi.org/10.1002/psp4.13099")!)
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

struct MedicationAnalytics: View {
    @Environment(Store.self) private var store
    @State private var days = 7
    @State private var now = Date()
    @State private var selected: Date?
    func amount(_ date: Date) -> Double {
        MedicationLevel.remaining(at: date, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: store.journal.halfLifeDays, now: now, model: store.journal.resolvedMedicationModel)
    }
    func rate(_ date: Date) -> Double {
        MedicationLevel.rate(at: date, doses: store.journal.doses, medication: store.journal.medication, halfLifeDays: store.journal.halfLifeDays, now: now, model: store.journal.resolvedMedicationModel)
    }
    var body: some View {
        let start = max(store.firstDoseDate ?? now, now.addingTimeInterval(-Double(days) * 86400))
        let span = max(0, now.timeIntervalSince(start))
        let dates = (span > 0 ? Array(0...240) : [0]).map { start.addingTimeInterval(span * Double($0) / 240) }
        let values = dates.map(amount)
        let average = span > 0 ? zip(values, values.dropFirst()).reduce(0.0) { $0 + ($1.0 + $1.1) / 2 } / 240 : amount(now)
        let timestamp = selected ?? now
        VStack(alignment: .leading, spacing: 16) {
            FilterBar(selection: $days, options: [(1, "Day"), (7, "Week"), (30, "Month")])
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Rate of change").font(.headline); Spacer(); Text("mg/h").font(.caption).foregroundStyle(.secondary) }
                Chart {
                    ForEach(dates, id: \.self) { date in
                        LineMark(x: .value("Date", date), y: .value("mg/h", rate(date))).foregroundStyle(Theme.pine)
                    }
                    RuleMark(y: .value("Zero", 0)).foregroundStyle(.secondary.opacity(0.3))
                    if let selected {
                        RuleMark(x: .value("Selected", selected)).foregroundStyle(.secondary)
                    }
                }.chartXSelection(value: $selected).frame(height: 170)
                HStack {
                    value("Per minute", rate(timestamp) / 60, unit: "mg/min")
                    Spacer()
                    value("Per hour", rate(timestamp), unit: "mg/h")
                }
                if selected != nil { Text(timestamp, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary) }
            }.card()
            HStack {
                value("Average level", average, unit: "mg")
                Spacer()
                value("Peak level", values.max() ?? 0, unit: "mg")
            }.frame(maxWidth: .infinity).card()
        }
        .onChange(of: days) { _, _ in selected = nil }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
    }
    func value(_ title: String, _ amount: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(amount.formatted(.number.precision(.fractionLength(0...6)))).font(.title3.weight(.semibold)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Text(unit).font(.caption).foregroundStyle(.secondary)
        }
    }
}
