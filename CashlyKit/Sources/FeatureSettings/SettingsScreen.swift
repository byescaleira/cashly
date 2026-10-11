import CashlyDesignSystem
import SwiftUI

public struct SettingsScreen: View {
    @Environment(SettingsModel.self) private var settings

    public init() {}

    public var body: some View {
        Group {
            #if os(macOS)
                Form { SettingsSections() }.formStyle(.grouped)
            #else
                AdaptiveList { SettingsSections() }
            #endif
        }
        .navigationTitle("Ajustes")
        .task { await settings.loadCloudAccount() }
    }
}

private struct SettingsSections: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        AppearanceSection()
        CurrencySection()
        NotificationSection()
        IntelligenceSection()
        CloudSection()
        if let data = settings.data { DataSection().environment(data) }
        GuidesSection()
        if settings.info.hasHelp { HelpSection() }
        AboutSection()
    }
}
