import SwiftUI

@main struct StillApp: App {
    @State private var store = Store()
    var body: some Scene {
        WindowGroup { RootView().environment(store).tint(Theme.pine) }
    }
}

enum Theme {
    static let pine = Color(light: UIColor(red: 0.37, green: 0.32, blue: 0.83, alpha: 1), dark: UIColor(red: 0.69, green: 0.65, blue: 1, alpha: 1))
    static let background = Color(light: UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1), dark: UIColor.black)
    static let card = Color(light: .white, dark: UIColor(white: 0.065, alpha: 1))
    static let sage = pine.opacity(0.10)
    static let aqua = Color(light: UIColor(red: 0.02, green: 0.46, blue: 0.43, alpha: 1), dark: UIColor(red: 0.39, green: 0.84, blue: 0.73, alpha: 1))
}
extension Color {
    init(light: UIColor, dark: UIColor) { self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light }) }
}
extension View {
    func card() -> some View { padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(.primary.opacity(0.035), lineWidth: 1)) }
}
func number(_ value: Double, digits: Int = 1) -> String { value.formatted(.number.precision(.fractionLength(0...digits))) }
