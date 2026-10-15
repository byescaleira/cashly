import CashlyDomain
import Foundation

extension SettingsModel {
    enum CloudStatus: Equatable {
        case unavailable, attention, pending, on, off

        var symbol: String {
            switch self {
            case .unavailable, .off: "icloud.slash"
            case .attention: "exclamationmark.icloud"
            case .pending: "arrow.clockwise.icloud"
            case .on: "checkmark.icloud"
            }
        }

        var title: String {
            switch self {
            case .unavailable: String(appLocalized: "Sync Unavailable")
            case .attention: String(appLocalized: "iCloud Needs Attention")
            case .pending: String(appLocalized: "Restart to Apply")
            case .on: String(appLocalized: "Syncing with iCloud")
            case .off: String(appLocalized: "Sync Is Off")
            }
        }
    }

    struct CloudScopeItem: Identifiable, Equatable {
        let symbol: String
        let title: String
        let detail: String?
        var id: String { symbol }
    }

    var cloudStatus: CloudStatus {
        guard isCloudAvailable else { return .unavailable }
        if needsRestart { return .pending }
        guard syncsAtLaunch else { return .off }
        switch cloudAccount {
        case .available, .checking: return .on
        case .noAccount, .restricted, .temporarilyUnavailable, .unavailable: return .attention
        }
    }

    func cloudDetail(now: Date) -> String {
        switch cloudStatus {
        case .unavailable:
            String(appLocalized: "Sync isn't available in this installation.")
        case .attention:
            accountDetail
        case .pending:
            syncsWithICloud
                ? String(appLocalized: "Sync turns on the next time Cashly opens.")
                : String(appLocalized: "Sync turns off the next time Cashly opens.")
        case .on:
            lastSync.map {
                String(
                    appLocalized:
                        "Last synced \(RelativeTime.moment($0, now: now, context: .middleOfSentence))."
                )
            } ?? String(appLocalized: "Waiting for the first sync.")
        case .off:
            String(appLocalized: "Your data stays on this device only.")
        }
    }

    var accountDetail: String {
        switch cloudAccount {
        case .noAccount:
            String(appLocalized: "Sign in to iCloud in the Settings app to sync your data.")
        case .restricted:
            String(appLocalized: "iCloud is restricted on this device by Screen Time or a profile.")
        case .temporarilyUnavailable:
            String(
                appLocalized: "iCloud is temporarily unavailable. Cashly tries again on its own.")
        case .unavailable, .checking, .available:
            String(appLocalized: "Couldn't reach iCloud. Check your connection.")
        }
    }

    var reachTitle: String {
        cloudStatus == .on
            ? String(appLocalized: "All your devices") : String(appLocalized: "This device only")
    }

    var cloudToggleFooter: String {
        guard isCloudAvailable else {
            return String(appLocalized: "Sync isn't available in this installation.")
        }
        return syncsWithICloud
            ? String(
                appLocalized:
                    "Turning sync off deletes nothing: this device keeps its data and the copy in iCloud stays in your account for your other devices."
            )
            : String(
                appLocalized:
                    "Turn it on to see the same data on every device signed in to your Apple Account. What's on this device joins what's already in iCloud."
            )
    }

    var syncedItems: [CloudScopeItem] {
        [
            CloudScopeItem(
                symbol: "person.2", title: String(appLocalized: "Profiles, categories and tags"),
                detail: nil),
            CloudScopeItem(
                symbol: "list.bullet.rectangle",
                title: String(appLocalized: "Transactions and budgets"),
                detail: String(appLocalized: "With splits, installments and captured payments.")),
            CloudScopeItem(
                symbol: "trophy", title: String(appLocalized: "Journey progress"),
                detail: String(appLocalized: "Levels, streaks, missions and achievements.")),
        ]
    }

    var localItems: [CloudScopeItem] {
        [
            CloudScopeItem(
                symbol: "slider.horizontal.3", title: String(appLocalized: "Preferences"),
                detail: String(
                    appLocalized: "Appearance, language, notifications and privacy, per device.")),
            CloudScopeItem(
                symbol: "externaldrive", title: String(appLocalized: "Backup files"),
                detail: String(
                    appLocalized:
                        "They go to iCloud Drive only if you turn it on in Data and Backup.")
            ),
        ]
    }
}
