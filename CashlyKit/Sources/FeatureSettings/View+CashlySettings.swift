import SwiftUI

extension View {
    public func cashlySettings(_ settings: SettingsModel) -> some View {
        modifier(AppearanceModifier()).environment(settings)
    }
}

private struct AppearanceModifier: ViewModifier {
    @Environment(SettingsModel.self) private var settings

    func body(content: Content) -> some View {
        content.onChange(of: settings.appearance, initial: true) { settings.appearance.apply() }
    }
}
