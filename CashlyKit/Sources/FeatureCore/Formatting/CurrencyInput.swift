import CashlyDomain
import Foundation

public enum CurrencyInput {
    public static let maximumDigits = 13

    public static func amount(typed text: String) -> Double {
        let digits = text.filter(\.isASCII).filter(\.isNumber).suffix(maximumDigits)
        return Money(minorUnits: Int64(digits) ?? 0).doubleValue
    }

    public static func clean(_ text: String) -> String {
        String(text.filter(\.isASCII).filter(\.isNumber).drop { $0 == "0" }.prefix(maximumDigits))
    }

    public static func digits(for amount: Double) -> String {
        let minorUnits = Int64((amount * 100).rounded())
        return minorUnits > 0 ? String(minorUnits) : ""
    }
}
