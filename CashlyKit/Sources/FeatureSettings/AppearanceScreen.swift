import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppearanceScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        SettingsPage("Appearance") {
            ThemeSection()
            AccentColorSection()
            PremiumColorSection(item: .accentMetallic, title: "Metallic")
            PremiumColorSection(item: .accentNeon, title: "Neon")
            if settings.supportsAppIcons { AppIconSection() }
        }
        .alert("Icon", isPresented: $settings.isShowingIconError) {
        } message: {
            Text(settings.iconError ?? "")
        }
    }
}
