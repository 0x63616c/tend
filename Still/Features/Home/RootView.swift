import SwiftUI
import Charts

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var selected = 0
    var body: some View {
        @Bindable var store = store
        TabView(selection: $selected) {
            TodayView().tag(0).tabItem { Label("Home", systemImage: "square.grid.2x2.fill").accessibilityIdentifier("navHome") }
            TreatmentView().tag(1).tabItem { Label("Treatment", systemImage: "syringe.fill").accessibilityIdentifier("navTreatment") }
            ProgressViewScreen().tag(2).tabItem { Label("Progress", systemImage: "chart.xyaxis.line").accessibilityIdentifier("navProgress") }
            JournalView().tag(3).tabItem { Label("Journal", systemImage: "book.closed").accessibilityIdentifier("navJournal") }
            SettingsView().tag(4).tabItem { Label("Settings", systemImage: "gearshape").accessibilityIdentifier("navSettings") }
        }
        .alert("Something needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .preferredColorScheme(store.journal.appearance == "dark" ? .dark : store.journal.appearance == "light" ? .light : nil)
        .task { await store.syncReminders() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refreshHealthKit() } }
        }
    }
}

struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var weightSheet = false
    @State private var doseSheet = false
    @State private var scheduleSheet = false
    @State private var weightDetail = false
    @State private var vialSheet = false
    var homeWeights: [WeightEntry] { store.treatmentWeights.filter { $0.date <= Date() } }
    var summary: WeightSummary { WeightSummary(entries: homeWeights, now: Date()) }
    var overdue: Date? { store.journal.schedule.outstanding(asOf: Date(), doses: store.journal.doses).first }
    var nextDate: Date? { overdue ?? store.journal.schedule.occurrences(after: Date(), count: 1).first }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PageHeader("Tendr").padding(.horizontal, 8)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(overdue == nil ? "Next dose" : "Overdue", systemImage: overdue == nil ? "calendar" : "clock.badge.exclamationmark").font(.caption.weight(.semibold)).foregroundStyle(overdue == nil ? Theme.pine : .orange)
                            if let nextDate {
                                HStack(alignment: .center, spacing: 8) {
                                    Text(nextDate, format: .dateTime.weekday(.wide)).font(.title3.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                    Spacer(minLength: 0)
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(nextDate, format: .dateTime.month(.abbreviated).day())
                                        Text(nextDate, format: .dateTime.hour().minute())
                                    }.font(.caption).foregroundStyle(.secondary).fixedSize()
                                }.frame(minHeight: 54)
                            } else { Button("Set your schedule") { scheduleSheet = true }.font(.headline) }
                            Button { doseSheet = true } label: { Label("Log dose", systemImage: "plus").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 3) }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).accessibilityIdentifier("logDose")
                        }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 128).card()
                        Button { vialSheet = true } label: {
                            if let vial = store.journal.vials.sorted(by: { $0.received > $1.received }).first { VialMini(vial: vial) }
                            else { VStack(spacing: 12) { Image(systemName: "plus").font(.title2); Text("Add vial").font(.caption.weight(.semibold)) }.frame(width: 82, height: 128).card() }
                        }.buttonStyle(.plain).accessibilityLabel("Vial details")
                            .accessibilityIdentifier("vialCard")
                    }
                    MedicationCard()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Weight", systemImage: "scalemass.fill").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.aqua)
                            Spacer()
                            Button { weightSheet = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }.frame(width: 44, height: 44).accessibilityLabel("Add Weight").accessibilityIdentifier("logWeight")
                        }
                        HStack(alignment: .center, spacing: 24) {
                            VStack(alignment: .leading, spacing: 5) {
                                if let latest = summary.latest {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(number(store.journal.unit.display(latest))).font(.system(size: 32, weight: .bold, design: .rounded))
                                        Text(store.journal.unit.symbol).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("No data").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                                }
                                Text("Latest").font(.caption).foregroundStyle(.secondary)
                            }
                            WeightChart(entries: homeWeights, unit: store.journal.unit, compact: true).frame(height: 65)
                        }
                        Divider()
                        HStack {
                            stat(title: (summary.lost ?? 0) >= 0 ? "Total lost" : "Total gained", value: summary.lost.map { number(store.journal.unit.display(abs($0))) }, suffix: store.journal.unit.symbol)
                            Spacer(); Divider().frame(height: 32); Spacer()
                            stat(title: "Weekly change", value: summary.weeklyChange.map { ($0 > 0 ? "+" : "") + number(store.journal.unit.display($0)) }, suffix: store.journal.unit.symbol, alignment: .trailing)
                        }
                    }.card().accessibilityIdentifier("weightCard").contentShape(Rectangle()).onTapGesture { weightDetail = true }

                }.padding(.horizontal, 16).padding(.bottom, 24)
            }.background(Theme.background).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $weightSheet) { WeightEditor() }
                .sheet(isPresented: $doseSheet) { DoseEditor(scheduledDate: nextDate) }
                .sheet(isPresented: $scheduleSheet) { ScheduleEditor() }
                .sheet(isPresented: $weightDetail) { ProgressViewScreen(isSheet: true) }
                .sheet(isPresented: $vialSheet) { VialEditor(vial: store.journal.vials.sorted { $0.received > $1.received }.first) }
        }
    }
    func stat(title: String, value: String?, suffix: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(.title3, design: .rounded, weight: .semibold)); Text(suffix).font(.caption).foregroundStyle(.secondary) }
            } else {
                Text("No data").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
        }
    }
}

struct WeightChart: View {
    var entries: [WeightEntry]
    var unit: WeightUnit
    @State private var selected: Date?
    var compact = false
    var sorted: [WeightEntry] { entries.sorted { $0.date < $1.date } }
    var bounds: ClosedRange<Double> {
        let values = sorted.map { unit.display($0.kilograms) }
        return ((values.min() ?? 0) - 1)...((values.max() ?? 1) + 1)
    }
    var body: some View {
        Chart {
            ForEach(sorted) { entry in
            AreaMark(x: .value("Date", entry.date), yStart: .value("Base", bounds.lowerBound), yEnd: .value("Weight", unit.display(entry.kilograms)))
                .foregroundStyle(LinearGradient(colors: [Theme.aqua.opacity(0.18), Theme.aqua.opacity(0.01)], startPoint: .top, endPoint: .bottom)).interpolationMethod(.catmullRom)
            LineMark(x: .value("Date", entry.date), y: .value("Weight", unit.display(entry.kilograms))).foregroundStyle(Theme.aqua).lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)).interpolationMethod(.catmullRom)
            if entry.id == sorted.last?.id { PointMark(x: .value("Date", entry.date), y: .value("Weight", unit.display(entry.kilograms))).foregroundStyle(Theme.aqua).symbolSize(45) }
            }
            if let selected, let nearest = sorted.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                RuleMark(x: .value("Selected", nearest.date)).foregroundStyle(.secondary.opacity(0.4)).annotation(position: .top) { Text("\(number(unit.display(nearest.kilograms))) \(unit.symbol)").font(.caption.bold()).padding(5).background(Theme.card, in: Capsule()) }
            }
        }.chartXSelection(value: $selected).chartYScale(domain: bounds)
            .chartXScale(range: .plotDimension(padding: compact ? 4 : 20))
            .chartXAxis { if !compact { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } } }
            .chartYAxis { if !compact { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.12)); AxisValueLabel() } } }
            .accessibilityLabel("Weight history in \(unit.symbol)")
    }
}

struct ProgressViewScreen: View {
    var isSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(Store.self) private var store
    @State private var range = 90
    @State private var adding = false
    var entries: [WeightEntry] { store.analyticsWeights.filter { $0.date <= Date() && (range == 0 || $0.date >= Calendar.current.date(byAdding: .day, value: -range, to: Date())!) }.sorted { $0.date < $1.date } }
    var summary: WeightSummary { WeightSummary(entries: entries, now: Date()) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !isSheet {
                        PageHeader("Progress") {
                            Button { adding = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }.frame(width: 44, height: 44)
                                .accessibilityLabel("Log weight")
                        }.padding(.horizontal, 8)
                    }
                    GoalCard()
                    Text("Weight").font(.title.bold())
                    FilterBar(selection: $range, options: [(30, "Month"), (90, "3 months"), (365, "Year"), (0, "All")])
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("WEIGHT TREND").font(.caption.bold()).tracking(1.5).foregroundStyle(.secondary)
                            Spacer()
                            if let latest = summary.latest {
                                Text("\(number(store.journal.unit.display(latest))) \(store.journal.unit.symbol)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                            }
                        }
                        if summary.latest != nil {
                            WeightChart(entries: entries, unit: store.journal.unit).frame(height: 220)
                        } else { ContentUnavailableView("Your story starts here", systemImage: "chart.xyaxis.line", description: Text("Add a weight entry to see your trend.")) }
                    }.card()
                    HStack(spacing: 14) {
                        metric(title: (summary.lost ?? 0) >= 0 ? "Weight lost" : "Weight gained", value: summary.lost.map { number(store.journal.unit.display(abs($0))) }, foot: store.journal.unit.symbol, icon: "arrow.down.right")
                        metric(title: "Weekly change", value: summary.weeklyChange.map { ($0 > 0 ? "+" : "") + number(store.journal.unit.display($0)) }, foot: "\(store.journal.unit.symbol) / week", icon: "waveform.path")
                    }
                    if let first = entries.first, let lost = summary.lost {
                        HStack { Image(systemName: "circle.lefthalf.filled").foregroundStyle(Theme.pine); Text("\(number(abs(lost) / first.kilograms * 100))% \(lost >= 0 ? "decrease" : "increase") over this period").font(.subheadline) }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Theme.sage, in: RoundedRectangle(cornerRadius: 20))
                    }
                    Text("Based on recorded weights in this period. Weekly change is the average from first to latest entry, not a prediction. Future entries are excluded.").font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 16).padding(.bottom, 24)
            }.background(Theme.background)
                .navigationTitle(isSheet ? "Progress" : "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(isSheet ? .visible : .hidden, for: .navigationBar)
                 .toolbar {
                    if isSheet { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
                }
                .sheet(isPresented: $adding) { WeightEditor() }
        }
    }
    func metric(title: String, value: String?, foot: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(Theme.pine)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value).font(.system(size: 28, weight: .semibold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
                    Text(foot).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
                }
            } else {
                Text("No data").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
