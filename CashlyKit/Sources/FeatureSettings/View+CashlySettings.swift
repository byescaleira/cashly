import CashlyDesignSystem
import SwiftUI

extension View {
    public func cashlySettings(_ settings: SettingsModel) -> some View {
        modifier(AppearanceModifier()).environment(settings).environment(settings.notifications)
    }
}

private struct AppearanceModifier: ViewModifier {
    @Environment(SettingsModel.self) private var settings

    func body(content: Content) -> some View {
        content
            .appTint(Color(hex: settings.tint))
            .environment(\.locale, settings.locale)
            .onChange(of: settings.appearance, initial: true) { settings.appearance.apply() }
            .onChange(of: settings.tint, initial: true) {
                Appearance.applyTint(Color(hex: settings.tint))
            }
    }
}
