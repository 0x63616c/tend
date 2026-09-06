import SwiftUI

@main struct StillApp: App {
    @State private var store = Store()
    var body: some Scene {
        WindowGroup { RootView().environment(store).tint(Theme.pine) }
    }
}

enum Theme {
    static let pine = Color.blue
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let sage = Color.blue.opacity(0.08)
}
extension Color {
    init(light: UIColor, dark: UIColor) { self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light }) }
}
extension View {
    func card() -> some View { padding(16).background(Theme.card, in: RoundedRectangle(cornerRadius: 12)) }
}
func number(_ value: Double, digits: Int = 1) -> String { value.formatted(.number.precision(.fractionLength(0...digits))) }
