import CashlyDomain
import FeatureCore

struct ReleaseNote: Identifiable, Equatable {
    let symbol: String
    let color: RetroColor
    let title: String
    let detail: String

    var id: String { symbol }
}

extension ReleaseNote {
    static var firstVersion: [ReleaseNote] {
        [
            ReleaseNote(
                symbol: "chart.bar", color: .olive,
                title: String(appLocalized: "Month at a Glance"),
                detail: String(
                    appLocalized: "Budgets with a pace bar that shows if spending is on track.")),
            ReleaseNote(
                symbol: "plus.circle", color: .tangerine,
                title: String(appLocalized: "Record in Seconds"),
                detail: String(
                    appLocalized:
                        "From the app, Siri, Shortcuts, Control Center or the Action button.")),
            ReleaseNote(
                symbol: "wallet.pass", color: .denim, title: String(appLocalized: "Wallet Capture"),
                detail: String(
                    appLocalized:
                        "An automation catches each card payment; you only pick the category.")),
            ReleaseNote(
                symbol: "person.2", color: .plum, title: String(appLocalized: "Split Expenses"),
                detail: String(
                    appLocalized: "Share a cost equally, by percentage or by a fixed amount.")),
            ReleaseNote(
                symbol: "trophy", color: .mustard, title: String(appLocalized: "Journey"),
                detail: String(
                    appLocalized: "Levels, streaks, missions and challenges for good money habits.")
            ),
            ReleaseNote(
                symbol: "square.grid.2x2", color: .sky, title: String(appLocalized: "Widgets"),
                detail: String(appLocalized: "Your budgets on the Home Screen and Lock Screen.")),
            ReleaseNote(
                symbol: "book", color: .avocado, title: String(appLocalized: "Guides"),
                detail: String(
                    appLocalized: "Fourteen short guides, from the first expense to backups.")),
            ReleaseNote(
                symbol: "externaldrive", color: .slate,
                title: String(appLocalized: "Your Data, Your Way"),
                detail: String(
                    appLocalized:
                        "iCloud sync, weekly backups and spreadsheets you can open anywhere.")),
            ReleaseNote(
                symbol: "globe", color: .teal, title: String(appLocalized: "Ten Languages"),
                detail: String(appLocalized: "Change the app's language right in Settings.")),
        ]
    }
}
