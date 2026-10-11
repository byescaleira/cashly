import SwiftUI

public struct SettingsScreen: View {
    @Environment(SettingsModel.self) private var settings

    public init() {}

    public var body: some View {
        Form {
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
        .formStyle(.grouped)
        .navigationTitle("Ajustes")
        .task { await settings.loadCloudAccount() }
    }
}
