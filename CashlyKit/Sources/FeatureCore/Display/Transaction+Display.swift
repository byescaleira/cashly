import CashlyDomain
import Foundation

extension Transaction {
    public var isConverted: Bool { exchange != nil || estimate != nil }

    public var displayAmount: String {
        isConverted ? "≈ \(money.formatted)" : money.formatted
    }

    public var originalAmount: String? {
        if let exchange { return exchange.money.formatted(currency: exchange.currencyCode) }
        return estimate.map { $0.money.formatted(currency: $0.currencyCode) }
    }

    public var amountAccessibilityLabel: String {
        guard let originalAmount else { return money.formatted }
        return String(appLocalized: "About \(money.formatted), from \(originalAmount)")
    }
}
