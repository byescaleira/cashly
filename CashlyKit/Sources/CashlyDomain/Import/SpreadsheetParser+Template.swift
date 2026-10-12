import Foundation

extension SpreadsheetParser {
    public static var template: String {
        let header = [
            SpreadsheetTerm.date, .summary, .category, .kind, .status, .amount, .installments,
            .tags,
        ].map(\.title).joined(separator: ";")
        let rows = [
            [
                "2026-10-05", String(appLocalized: "Supermarket"),
                String(appLocalized: "Groceries"),
                SpreadsheetTerm.expense.title, SpreadsheetTerm.paid.title,
                SpreadsheetTerm.amount(24590),
                "1", String(appLocalized: "Housing"),
            ],
            [
                "2026-10-05", String(appLocalized: "Salary"), String(appLocalized: "Work"),
                SpreadsheetTerm.income.title, SpreadsheetTerm.paid.title,
                SpreadsheetTerm.amount(500_000),
                "1", "",
            ],
            [
                "2026-10-12", String(appLocalized: "Laptop"), String(appLocalized: "Technology"),
                SpreadsheetTerm.expense.title, SpreadsheetTerm.toPay.title,
                SpreadsheetTerm.amount(360_000), "10", "",
            ],
        ]
        return ([header] + rows.map { $0.joined(separator: ";") }).map { $0 + "\r\n" }.joined()
    }
}
