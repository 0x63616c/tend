import SwiftUI
import Charts

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var selected = 0
    var body: some View {
        @Bindable var store = store
        TabView(selection: $selected) {
            TodayView().tag(0).tabItem { Label("Summary", systemImage: "heart.fill") }
            ProgressViewScreen().tag(1).tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
            JournalView().tag(2).tabItem { Label("Journal", systemImage: "book.closed") }
            AssistantPreview().tag(3).tabItem { Label("Assistant", systemImage: "sparkles") }
            SettingsView().tag(4).tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .alert("Something needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .preferredColorScheme(store.journal.appearance == "dark" ? .dark : store.journal.appearance == "light" ? .light : nil)
        .task { await store.syncReminders() }
    }
}

struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var weightSheet = false
    @State private var doseSheet = false
    @State private var scheduleSheet = false
    var summary: WeightSummary { WeightSummary(entries: store.journal.weights, now: Date()) }
    var overdue: Date? { store.journal.schedule.outstanding(asOf: Date(), doses: store.journal.doses).first }
    var nextDate: Date? { overdue ?? store.journal.schedule.occurrences(after: Date(), count: 1).first }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day()).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        if store.demo { Text("DEMO").font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.secondary).padding(.horizontal, 8).padding(.vertical, 4).background(.quaternary, in: Capsule()) }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: overdue == nil ? "syringe.fill" : "clock.badge.exclamationmark").font(.title3).foregroundStyle(overdue == nil ? .blue : .orange).frame(width: 42, height: 42).background((overdue == nil ? Color.blue : Color.orange).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(overdue == nil ? "Next dose" : "Dose overdue").font(.subheadline.weight(.semibold))
                            if let nextDate { Text(nextDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Button("Log") { doseSheet = true }.font(.subheadline.weight(.semibold)).buttonStyle(.borderedProminent).buttonBorderShape(.capsule).accessibilityIdentifier("logDose")
                    }.card()
                    MedicationCard()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Weight", systemImage: "scalemass.fill").font(.subheadline.weight(.semibold)).foregroundStyle(.teal)
                            Spacer()
                            Button { weightSheet = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }.accessibilityLabel("Add Weight").accessibilityIdentifier("logWeight")
                        }
                        HStack(alignment: .center, spacing: 24) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(summary.latest.map { number(store.journal.unit.display($0)) } ?? "—").font(.system(size: 32, weight: .bold, design: .rounded))
                                    Text(store.journal.unit.rawValue).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Text("Latest weight").font(.caption).foregroundStyle(.secondary)
                            }
                            WeightChart(entries: store.journal.weights.filter { $0.date <= Date() }, unit: store.journal.unit, compact: true).frame(height: 65)
                        }
                        Divider()
                        HStack {
                            stat(title: (summary.lost ?? 0) >= 0 ? "Total lost" : "Total gained", value: summary.lost.map { number(store.journal.unit.display(abs($0))) } ?? "—", suffix: store.journal.unit.rawValue)
                            Spacer(); Divider().frame(height: 32); Spacer()
                            stat(title: "Weekly change", value: summary.weeklyChange.map { ($0 > 0 ? "+" : "") + number(store.journal.unit.display($0)) } ?? "—", suffix: store.journal.unit.rawValue)
                        }
                    }.card()
                    if let vial = store.journal.vials.sorted(by: { $0.received > $1.received }).first { VialSummary(vial: vial) }
                }.padding(.horizontal, 16).padding(.bottom, 24)
            }.background(Theme.background).navigationTitle("Tend")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { scheduleSheet = true } label: { Image(systemName: "calendar") }.accessibilityLabel("Edit schedule") } }
                .sheet(isPresented: $weightSheet) { WeightEditor() }
                .sheet(isPresented: $doseSheet) { DoseEditor(scheduledDate: nextDate) }
                .sheet(isPresented: $scheduleSheet) { ScheduleEditor() }
        }
    }
    func stat(title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(.title3, design: .rounded, weight: .semibold)); Text(suffix).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct WeightChart: View {
    var entries: [WeightEntry]
    var unit: WeightUnit
    var compact = false
    var sorted: [WeightEntry] { entries.sorted { $0.date < $1.date } }
    var bounds: ClosedRange<Double> {
        let values = sorted.map { unit.display($0.kilograms) }
        return ((values.min() ?? 0) - 1)...((values.max() ?? 1) + 1)
    }
    var body: some View {
        Chart(sorted) { entry in
            AreaMark(x: .value("Date", entry.date), yStart: .value("Base", bounds.lowerBound), yEnd: .value("Weight", unit.display(entry.kilograms)))
                .foregroundStyle(LinearGradient(colors: [Theme.pine.opacity(0.18), Theme.pine.opacity(0.01)], startPoint: .top, endPoint: .bottom)).interpolationMethod(.monotone)
            LineMark(x: .value("Date", entry.date), y: .value("Weight", unit.display(entry.kilograms))).foregroundStyle(Theme.pine).lineStyle(StrokeStyle(lineWidth: 2.5)).interpolationMethod(.monotone)
            if entry.id == sorted.last?.id { PointMark(x: .value("Date", entry.date), y: .value("Weight", unit.display(entry.kilograms))).foregroundStyle(Theme.pine).symbolSize(45) }
        }.chartYScale(domain: bounds)
            .chartXAxis { if !compact { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } } }
            .chartYAxis { if !compact { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.12)); AxisValueLabel() } } }
            .accessibilityLabel("Weight history in \(unit.rawValue)")
    }
}

struct ProgressViewScreen: View {
    @Environment(Store.self) private var store
    @State private var range = 90
    @State private var adding = false
    var entries: [WeightEntry] { store.journal.weights.filter { $0.date <= Date() && (range == 0 || $0.date >= Calendar.current.date(byAdding: .day, value: -range, to: Date())!) }.sorted { $0.date < $1.date } }
    var summary: WeightSummary { WeightSummary(entries: entries, now: Date()) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Weight").font(.title.bold())
                    Picker("Date range", selection: $range) { Text("Month").tag(30); Text("3 months").tag(90); Text("Year").tag(365); Text("All").tag(0) }.pickerStyle(.segmented)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("WEIGHT TREND").font(.caption.bold()).tracking(1.5).foregroundStyle(.secondary)
                        if let latest = summary.latest {
                            HStack(alignment: .firstTextBaseline) { Text(number(store.journal.unit.display(latest))).font(.system(size: 52, weight: .medium, design: .rounded)); Text(store.journal.unit.rawValue).foregroundStyle(.secondary) }
                            WeightChart(entries: entries, unit: store.journal.unit).frame(height: 220)
                        } else { ContentUnavailableView("Your story starts here", systemImage: "chart.xyaxis.line", description: Text("Add a weight entry to see your trend.")) }
                    }.card()
                    HStack(spacing: 14) {
                        metric(title: (summary.lost ?? 0) >= 0 ? "Weight lost" : "Weight gained", value: summary.lost.map { number(store.journal.unit.display(abs($0))) } ?? "—", foot: store.journal.unit.rawValue, icon: "arrow.down.right")
                        metric(title: "Weekly change", value: summary.weeklyChange.map { ($0 > 0 ? "+" : "") + number(store.journal.unit.display($0)) } ?? "—", foot: "\(store.journal.unit.rawValue) / week", icon: "waveform.path")
                    }
                    if let first = entries.first, let lost = summary.lost {
                        HStack { Image(systemName: "circle.lefthalf.filled").foregroundStyle(Theme.pine); Text("\(number(abs(lost) / first.kilograms * 100))% \(lost >= 0 ? "decrease" : "increase") over this period").font(.subheadline) }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Theme.sage, in: RoundedRectangle(cornerRadius: 20))
                    }
                    Text("Based on recorded weights in this period. Weekly change is the average from first to latest entry, not a prediction. Future entries are excluded.").font(.caption).foregroundStyle(.secondary)
                }.padding(22)
            }.background(Theme.background).navigationTitle("Progress").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Log weight") }
                .sheet(isPresented: $adding) { WeightEditor() }
        }
    }
    func metric(title: String, value: String, foot: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.pine)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 28, weight: .semibold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            Text(foot).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
