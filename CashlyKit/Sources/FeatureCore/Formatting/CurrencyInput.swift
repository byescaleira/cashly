import CashlyDomain
import Foundation

public enum CurrencyInput {
    public static let maximumDigits = 13

    public static func amount(typed text: String, fractionDigits: Int = 2) -> Double {
        let digits = text.filter(\.isASCII).filter(\.isNumber).suffix(maximumDigits)
        let units = Decimal(Int64(digits) ?? 0) / scale(fractionDigits)
        return NSDecimalNumber(decimal: units).doubleValue
    }

    public static func clean(_ text: String) -> String {
        String(text.filter(\.isASCII).filter(\.isNumber).drop { $0 == "0" }.prefix(maximumDigits))
    }

    public static func digits(for amount: Double, fractionDigits: Int = 2) -> String {
        guard amount.isFinite else { return "" }
        let units = Int64(
            (amount * NSDecimalNumber(decimal: scale(fractionDigits)).doubleValue).rounded())
        return units > 0 ? String(units) : ""
    }

    public static func fractionDigits(for code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return min(max(formatter.maximumFractionDigits, 0), 2)
    }

    private static func scale(_ fractionDigits: Int) -> Decimal {
        pow(Decimal(10), min(max(fractionDigits, 0), 2))
    }
}
