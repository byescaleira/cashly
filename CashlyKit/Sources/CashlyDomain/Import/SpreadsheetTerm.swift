import Foundation

public enum SpreadsheetTerm: CaseIterable, Sendable {
    case date, user, summary, category, kind, status, amount, currency, installments, tags
    case income, expense, paid, toPay, toReceive, canceled

    public var title: String { String(appLocalized: value) }

    public var translations: Set<String> { String.localizations(of: value) }

    public static func amount(_ minorUnits: Int64) -> String {
        let sign = minorUnits < 0 ? "-" : ""
        let value = minorUnits.magnitude
        let cents = String(value % 100)
        let separator = Locale.app.decimalSeparator ?? "."
        return sign + String(value / 100) + separator
            + String(repeating: "0", count: 2 - cents.count) + cents
    }

    private var value: String.LocalizationValue {
        switch self {
        case .date: "Date"
        case .user: "Profile"
        case .summary: "Description"
        case .category: "Category"
        case .kind: "Type"
        case .status: "Status"
        case .amount: "Amount"
        case .currency: "Currency"
        case .installments: "Installments"
        case .tags: "Tags"
        case .income: "Income"
        case .expense: "Expense"
        case .paid: "Paid"
        case .toPay: "To pay"
        case .toReceive: "To receive"
        case .canceled: "Canceled"
        }
    }
}
