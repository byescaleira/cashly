import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
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
        .navigationTitle("Settings")
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
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    let extra: Extra

    var body: some View {
        ProRow()
        Section {
            SettingsRow(
                "Appearance", symbol: "paintbrush", color: RetroColor.tangerine.color,
                value: settings.appearance.title
            ) {
                SettingsPage("Appearance") { AppearanceSection() }
            }
            SettingsRow(
                "Language", symbol: "globe", color: RetroColor.teal.color,
                value: settings.language.nativeName
            ) {
                SettingsPage("Language") { LanguageSection() }
            }
            SettingsRow(
                "Currency", symbol: "dollarsign.circle", color: RetroColor.olive.color,
                value: settings.currencyName(settings.currency)
            ) {
                SettingsPage("Currency") { CurrencySection() }
            }
            SettingsRow(
                "Notifications", symbol: "bell", color: RetroColor.cherry.color,
                value: notifications.isAnyOn
                    ? String(appLocalized: "On") : String(appLocalized: "Off")
            ) {
                SettingsPage("Notifications") { NotificationSection() }
            }
            SettingsRow(
                "Privacy", symbol: "lock", color: RetroColor.plum.color,
                value: settings.locksApp || settings.isDiscreet
                    ? String(appLocalized: "On") : String(appLocalized: "Off")
            ) {
                SettingsPage("Privacy") { PrivacySection() }
            }
            if flags?.isOn(.journey) != false {
                SettingsRow(
                    "Journey", symbol: "trophy", color: RetroColor.mustard.color,
                    value: settings.showsJourney
                        ? String(appLocalized: "On") : String(appLocalized: "Off")
                ) {
                    SettingsPage("Journey") { JourneySection() }
                }
            }
        } header: {
            Text("General")
        }
        Section {
            SettingsRow(
                "iCloud", symbol: "icloud", color: RetroColor.sky.color,
                value: settings.isSyncOn ? String(appLocalized: "On") : String(appLocalized: "Off")
            ) {
                SettingsPage("iCloud") { CloudSection() }
            }
            if let data = settings.data {
                SettingsRow(
                    "Data and Backup", symbol: "externaldrive", color: RetroColor.slate.color
                ) {
                    SettingsPage("Data and Backup") { DataSection() }.environment(data)
                }
            }
            extra
        } header: {
            Text("Data")
        }
        Section {
            if showGuide != nil, flags?.isOn(.guides) != false {
                SettingsRow("Guides", symbol: "book", color: RetroColor.avocado.color) {
                    SettingsPage("Guides") { GuidesSection() }
                }
            }
            SettingsRow(
                "About Cashly", symbol: "info.circle", color: RetroColor.indigo.color,
                value: settings.info.version
            ) {
                SettingsPage("About Cashly") {
                    AboutSection()
                    if settings.info.hasHelp { HelpSection() }
                }
            }
        } header: {
            Text("Help")
        }
        DevelopmentRow()
    }
}

private struct ProRow: View {
    @Environment(StoreModel.self) private var store

    var body: some View {
        Section {
            SettingsRow(
                "Cashly Pro", symbol: "crown", color: RetroColor.mustard.color,
                value: store.entitlement.title
            ) {
                SettingsPage("Cashly Pro") { ProSection() }
            }
        }
    }
}

private struct DevelopmentRow: View {
    @Environment(\.featureFlags) private var flags

    var body: some View {
        #if DEBUG
            if flags != nil {
                Section {
                    SettingsRow("Developer", symbol: "hammer", color: RetroColor.coffee.color) {
                        SettingsPage("Developer") { DeveloperSections() }
                    }
                }
            }
        #endif
    }
}
