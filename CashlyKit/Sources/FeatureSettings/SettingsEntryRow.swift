import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct SettingsEntryRow: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(NotificationsModel.self) private var notifications
    @Environment(FinanceModel.self) private var finance: FinanceModel?
    @Environment(AppLockModel.self) private var lock: AppLockModel?
    @Environment(\.pro) private var pro
    let entry: SettingsEntry

    var body: some View {
        SettingsRow(
            verbatim: entry.title, symbol: entry.symbol, color: entry.color.color, value: value,
            detail: entry.detail
        ) {
            SettingsDestination(entry: entry)
        }
    }

    private var value: String? {
        switch entry {
        case .appearance: settings.appearance.title
        case .language: settings.languageValue
        case .currency: settings.currencyValue
        case .notifications: notifications.overviewValue
        case .privacy: settings.privacyValue(lock?.biometry ?? .none)
        case .widgets: settings.widgetValue(categories: finance?.allCategories ?? [])
        case .journey: settings.journeyValue
        case .cloud: settings.cloudValue
        case .about: settings.info.version
        case .data: settings.data?.overviewValue(now: .now)
        case .web: settings.web.map { pro.lockedValue ?? $0.overviewValue }
        case .guides, .shop: nil
        }
    }
}

private struct SettingsDestination: View {
    @Environment(SettingsModel.self) private var settings
    let entry: SettingsEntry

    var body: some View {
        switch entry {
        case .appearance: AppearanceScreen()
        case .language: LanguageScreen()
        case .currency: CurrencyScreen()
        case .notifications: NotificationScreen()
        case .privacy: PrivacyScreen()
        case .widgets: SettingsPage("Widgets") { WidgetsSection() }
        case .journey: JourneySettingsScreen()
        case .cloud: SettingsPage("iCloud") { CloudSection() }
        case .data:
            if let data = settings.data {
                SettingsPage("Data and Backup") { DataSection() }.environment(data)
            }
        case .web:
            if let web = settings.web {
                WebSharingScreen().environment(web)
            }
        case .guides: GuidesHubScreen()
        case .about: AboutScreen()
        case .shop: RouteView(.shop)
        }
    }
}
