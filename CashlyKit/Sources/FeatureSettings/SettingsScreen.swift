import SwiftUI

public struct SettingsScreen: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        Form {
            AppearanceSection()
            CurrencySection()
            NotificationSection()
            IntelligenceSection()
            CloudSection()
            if let data = settings.data { DataSection().environment(data) }
            if settings.info.hasHelp { HelpSection() }
            AboutSection()
        }
        .formStyle(.grouped)
        .navigationTitle("Ajustes")
        #if !os(macOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        #endif
        .task { await settings.loadCloudAccount() }
    }
}
