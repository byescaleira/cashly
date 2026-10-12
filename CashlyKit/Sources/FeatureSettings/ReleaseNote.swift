import CashlyDomain

struct ReleaseNote: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }

    static var current: [ReleaseNote] {
        [
            ReleaseNote(
                symbol: "gearshape", title: String(appLocalized: "Settings"),
                detail: String(
                    appLocalized: "Theme, icon and currency in one place, from your avatar menu.")),
            ReleaseNote(
                symbol: "externaldrive", title: String(appLocalized: "Backup and Spreadsheet"),
                detail:
                    String(
                        appLocalized:
                            "Export and import your data, create a spreadsheet of your transactions and turn on the weekly automatic backup."
                    )
            ),
            ReleaseNote(
                symbol: "bell", title: String(appLocalized: "Reminders"),
                detail: String(
                    appLocalized:
                        "Alerts on the day bills are due or money is expected, and at the start of each month."
                )),
            ReleaseNote(
                symbol: "rectangle.split.2x1", title: String(appLocalized: "Column Layouts"),
                detail: String(
                    appLocalized:
                        "On iPad and Mac, Home and categories make use of the screen width.")),
        ]
    }
}
