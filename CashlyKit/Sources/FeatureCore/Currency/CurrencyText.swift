import CashlyDomain
import Foundation

public enum CurrencyText {
    public static func name(_ code: String) -> String {
        let name = Locale.app.localizedString(forCurrencyCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    public static func symbol(_ code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .app
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }

    public static func rate(_ rate: Decimal, from: String, to: String) -> String {
        let one = Decimal(1).formatted(
            .currency(code: from).precision(.fractionLength(0)).locale(.app))
        let value = rate.formatted(
            .currency(code: to).precision(.significantDigits(1...6)).locale(.app))
        return "\(one) = \(value)"
    }

    public static func label(_ code: String) -> String {
        "\(name(code)) · \(code)"
    }

    public static func estimate(_ estimate: CurrencyEstimate) -> String {
        let day = estimate.date.formatted(.dateTime.day().month(.abbreviated).year().locale(.app))
        return String(
            appLocalized:
                "Saved as \(estimate.money.formatted(currency: estimate.currencyCode)) in \(name(estimate.currencyCode)). Shown converted at the rate from \(day)."
        )
    }

    public static func sections(codes: [String], suggested: [String], query: String)
        -> [CurrencyGroup]
    {
        let names = Dictionary(uniqueKeysWithValues: Set(codes).map { ($0, name($0)) })
        let ordered = codes.sorted {
            (names[$0] ?? $0).localizedStandardCompare(names[$1] ?? $1) == .orderedAscending
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else {
            let matches = ordered.filter {
                $0.localizedStandardContains(trimmed)
                    || (names[$0] ?? "").localizedStandardContains(trimmed)
                    || symbol($0).localizedStandardContains(trimmed)
            }
            return matches.isEmpty ? [] : [CurrencyGroup(title: nil, codes: matches)]
        }
        let top = suggested.filter(codes.contains)
        return [
            CurrencyGroup(title: "Suggested", codes: top),
            CurrencyGroup(title: "All Currencies", codes: ordered.filter { !top.contains($0) }),
        ].filter { !$0.codes.isEmpty }
    }
}
