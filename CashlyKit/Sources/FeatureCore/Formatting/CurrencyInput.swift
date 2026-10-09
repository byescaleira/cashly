import CashlyDomain

public enum CurrencyInput {
    public static let maximumDigits = 13

    public static func amount(typed text: String) -> Double {
        let digits = text.filter(\.isASCII).filter(\.isNumber).suffix(maximumDigits)
        return Money(minorUnits: Int64(digits) ?? 0).doubleValue
    }
}
