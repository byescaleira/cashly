import CashlyDesignSystem
import SwiftUI

public struct SettingsScreen<Extra: View>: View {
    @Environment(SettingsModel.self) private var settings
    private let extra: Extra

    public init(@ViewBuilder extra: () -> Extra) {
        self.extra = extra()
    }

    public var body: some View {
        Group {
            #if os(macOS)
                Form { SettingsSections(extra: extra) }.formStyle(.grouped)
            #else
                AdaptiveList { SettingsSections(extra: extra) }
            #endif
        }
        .navigationTitle("Ajustes")
        .task { await settings.loadCloudAccount() }
    }
}

extension SettingsScreen where Extra == EmptyView {
    public init() {
        self.init { EmptyView() }
    }
}

private struct SettingsSections<Extra: View>: View {
    @Environment(SettingsModel.self) private var settings
    let extra: Extra

    var body: some View {
        AppearanceSection()
        CurrencySection()
        NotificationSection()
        IntelligenceSection()
        CloudSection()
        if let data = settings.data { DataSection().environment(data) }
        GuidesSection()
        extra
        if settings.info.hasHelp { HelpSection() }
        AboutSection()
        FlagsSection()
    }
}
