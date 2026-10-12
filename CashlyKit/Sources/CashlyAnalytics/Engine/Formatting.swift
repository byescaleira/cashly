import CashlyDomain
import Foundation

enum Formatting {
    static func money(_ minorUnits: Int64) -> String {
        (Double(minorUnits) / 100).formatted(
            .currency(code: Money.currencyCode).locale(.app))
    }

    static func shortMonth(_ month: YearMonth) -> String {
        month.startDate.formatted(
            .dateTime.month(.abbreviated).locale(.app)
        )
        .replacingOccurrences(of: ".", with: "")
    }

    static func month(_ month: YearMonth) -> String {
        month.startDate.formatted(
            .dateTime.month(.abbreviated).year().locale(.app))
    }
}
