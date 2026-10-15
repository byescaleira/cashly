import CashlyDomain
import FeatureCore
import Foundation

enum SettingsGroup: CaseIterable, Identifiable {
    case general, data, help

    var id: Self { self }

    var title: String {
        switch self {
        case .general: String(appLocalized: "General")
        case .data: String(appLocalized: "Data")
        case .help: String(appLocalized: "Help")
        }
    }
}

enum SettingsEntry: String, CaseIterable, Identifiable {
    case appearance, language, currency, notifications, privacy, widgets, journey
    case cloud, data
    case guides, about

    var id: String { rawValue }

    var group: SettingsGroup {
        switch self {
        case .appearance, .language, .currency, .notifications, .privacy, .widgets, .journey:
            .general
        case .cloud, .data: .data
        case .guides, .about: .help
        }
    }

    var title: String {
        switch self {
        case .appearance: String(appLocalized: "Appearance")
        case .language: String(appLocalized: "Language")
        case .currency: String(appLocalized: "Currency")
        case .notifications: String(appLocalized: "Notifications")
        case .privacy: String(appLocalized: "Privacy")
        case .widgets: String(appLocalized: "Widgets")
        case .journey: String(appLocalized: "Journey")
        case .cloud: String(appLocalized: "iCloud")
        case .data: String(appLocalized: "Data and Backup")
        case .guides: String(appLocalized: "Guides")
        case .about: String(appLocalized: "About Cashly")
        }
    }

    var keywords: String {
        switch self {
        case .appearance:
            String(appLocalized: "theme, dark mode, light mode, accent color, app icon")
        case .language: String(appLocalized: "translation, English, region")
        case .currency: String(appLocalized: "money, symbol, real, dollar, euro")
        case .notifications:
            String(appLocalized: "reminders, alerts, bills, weekly summary, permission")
        case .privacy: String(appLocalized: "Face ID, Touch ID, passcode, lock, hide amounts")
        case .widgets: String(appLocalized: "Home Screen, Lock Screen, Control Center")
        case .journey: String(appLocalized: "level, streak, missions, challenges, achievements")
        case .cloud: String(appLocalized: "sync, devices, account")
        case .data: String(appLocalized: "backup, export, import, spreadsheet, CSV, erase")
        case .guides: String(appLocalized: "help, tutorial, how to")
        case .about: String(appLocalized: "version, support, terms, what's new")
        }
    }

    var symbol: String {
        switch self {
        case .appearance: "paintbrush"
        case .language: "globe"
        case .currency: "banknote"
        case .notifications: "bell"
        case .privacy: "lock"
        case .widgets: "square.grid.2x2"
        case .journey: "trophy"
        case .cloud: "icloud"
        case .data: "externaldrive"
        case .guides: "book"
        case .about: "info.circle"
        }
    }

    var color: RetroColor {
        switch self {
        case .appearance: .tangerine
        case .language: .teal
        case .currency: .olive
        case .notifications: .cherry
        case .privacy: .plum
        case .widgets: .denim
        case .journey: .mustard
        case .cloud: .sky
        case .data: .slate
        case .guides: .avocado
        case .about: .indigo
        }
    }

    func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return title.localizedStandardContains(trimmed)
            || keywords.localizedStandardContains(trimmed)
    }
}
