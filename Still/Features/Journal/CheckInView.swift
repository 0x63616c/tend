import SwiftUI
import Charts

struct CheckInCard: View {
    @Environment(Store.self) private var store
    @State private var adding = false
    var body: some View {
        Button { adding = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "face.smiling").font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) { Text("How are you feeling?").font(.subheadline.weight(.semibold)); Text("A quick appetite & nausea check-in").font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Theme.pine)
            }.card()
        }.buttonStyle(.plain).sheet(isPresented: $adding) { CheckInEditor() }
    }
}
struct CheckInEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: CheckIn?
    @State private var appetite: Int?
    @State private var nausea: Int?
    @State private var date = Date()
    @State private var note = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rating(title: "Appetite", low: "Not hungry", high: "Very hungry", selection: $appetite, color: Theme.aqua)
                    rating(title: "Nausea", low: "None", high: "Severe", selection: $nausea, color: .orange)
                    VStack(spacing: 16) { DatePicker("Date", selection: $date, in: ...Date()); DisclosureGroup("Note") { TextField("Anything to add?", text: $note, axis: .vertical).lineLimit(2...5) } }.card()
                }.padding(20)
            }.background(Theme.background).navigationTitle("Check-in").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) { Button {
                    var updated = CheckIn(date: date, appetite: appetite, nausea: nausea, note: note)
                    if let entry { updated.id = entry.id }
                    guard updated.isValid else { return }
                    var next = store.journal; next.checkIns.removeAll { $0.id == updated.id }; next.checkIns.append(updated)
                    if store.commit(next) { dismiss() }
                } label: { Text("Save Check-in").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 9) }.buttonStyle(.borderedProminent).disabled(appetite == nil && nausea == nil).padding(20).background(.bar) }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .onAppear { if let entry { appetite = entry.appetite; nausea = entry.nausea; date = entry.date; note = entry.note } }
        }
    }
    func rating(title: String, low: String, high: String, selection: Binding<Int?>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title).font(.title3.weight(.semibold))
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { score in
                    Button { selection.wrappedValue = selection.wrappedValue == score ? nil : score } label: {
                        Text("\(score)").font(.system(.title3, design: .rounded, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 46).background(selection.wrappedValue == score ? color : color.opacity(0.08), in: Circle()).foregroundStyle(selection.wrappedValue == score ? Theme.background : color)
                    }.accessibilityLabel("\(title) \(score) of 5").accessibilityAddTraits(selection.wrappedValue == score ? .isSelected : [])
                }
            }
            HStack { Text(low); Spacer(); Text(high) }.font(.caption).foregroundStyle(.secondary)
        }.card()
    }
}
struct CheckInTrends: View {
    @Environment(Store.self) private var store
    var entries: [CheckIn] { store.journal.checkIns.filter { $0.date <= Date() }.sorted { $0.date < $1.date } }
    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("How you've felt").font(.headline)
                Chart(entries) { entry in
                    if let appetite = entry.appetite { LineMark(x: .value("Date", entry.date), y: .value("Rating", appetite), series: .value("Rating", "Appetite")).foregroundStyle(by: .value("Rating", "Appetite")).symbol(.circle) }
                    if let nausea = entry.nausea { LineMark(x: .value("Date", entry.date), y: .value("Rating", nausea), series: .value("Rating", "Nausea")).foregroundStyle(by: .value("Rating", "Nausea")).symbol(.circle) }
                }.chartForegroundStyleScale(["Appetite": Theme.aqua, "Nausea": Color.orange]).chartYScale(domain: 1...5).chartYAxis { AxisMarks(values: [1, 3, 5]) }.frame(height: 180)
                Text("Appetite: 1 not hungry → 5 very hungry\nNausea: 1 none → 5 severe").font(.caption2).foregroundStyle(.secondary)
            }.card()
        }
    }
}
