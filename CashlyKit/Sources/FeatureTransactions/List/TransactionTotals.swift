import FeatureCore
import Foundation

public struct TransactionTotals: Equatable, Sendable {
    public let count: Int
    public let spent: Double
    public let received: Double
    public let balance: Double

    public init(count: Int = 0, spent: Double = 0, received: Double = 0, balance: Double = 0) {
        self.count = count
        self.spent = spent
        self.received = received
        self.balance = balance
    }

    public var isIncomeOnly: Bool { spent == 0 && received > 0 }
    public var isMixed: Bool { spent > 0 && received > 0 }
    public var amount: Double { isIncomeOnly ? received : spent }

    public var caption: String {
        isIncomeOnly ? String(appLocalized: "Received") : String(appLocalized: "Spent")
    }
}
