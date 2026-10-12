import CashlyDesignSystem
import FeatureCore
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
    @Environment(NotificationsModel.self) private var notifications
    @Environment(IntelligenceModel.self) private var intelligence: IntelligenceModel?
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    @Environment(\.appTint) private var appTint
    let extra: Extra

    var body: some View {
        Section {
            SettingsRow(
                "Aparência", symbol: "paintbrush", color: appTint, value: settings.appearance.title
            ) {
                SettingsPage("Aparência") { AppearanceSection() }
            }
            SettingsRow(
                "Moeda", symbol: "dollarsign.circle", color: .companion,
                value: settings.currencyName(settings.currency)
            ) {
                SettingsPage("Moeda") { CurrencySection() }
            }
            SettingsRow(
                "Notificações", symbol: "bell", color: appTint,
                value: notifications.isAnyOn ? "Ligadas" : "Desligadas"
            ) {
                SettingsPage("Notificações") { NotificationSection() }
            }
        } header: {
            Text("Geral")
        }
        Section {
            SettingsRow(
                "iCloud", symbol: "icloud", color: appTint,
                value: settings.isSyncOn ? "Ligado" : "Desligado"
            ) {
                SettingsPage("iCloud") { CloudSection() }
            }
            if let data = settings.data {
                SettingsRow("Dados e backup", symbol: "externaldrive", color: .companion) {
                    SettingsPage("Dados e backup") { DataSection() }.environment(data)
                }
            }
            if intelligence != nil {
                SettingsRow("Inteligência", symbol: "cpu", color: appTint) { IntelligenceScreen() }
            }
            extra
        } header: {
            Text("Dados")
        }
        Section {
            if showGuide != nil, flags?.isOn(.guides) != false {
                SettingsRow("Guias", symbol: "book", color: appTint) {
                    SettingsPage("Guias") { GuidesSection() }
                }
            }
            SettingsRow(
                "Sobre o Cashly", symbol: "info.circle", color: .companion,
                value: settings.info.version
            ) {
                SettingsPage("Sobre o Cashly") {
                    AboutSection()
                    if settings.info.hasHelp { HelpSection() }
                }
            }
        } header: {
            Text("Ajuda")
        }
        DevelopmentRow()
    }
}

private struct DevelopmentRow: View {
    @Environment(\.featureFlags) private var flags
    @Environment(\.appTint) private var appTint

    var body: some View {
        #if DEBUG
            if flags != nil {
                Section {
                    SettingsRow("Desenvolvimento", symbol: "hammer", color: appTint) {
                        SettingsPage("Desenvolvimento") { FlagsSection() }
                    }
                }
            }
        #endif
    }
}
