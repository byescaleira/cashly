import Foundation

/// Query-time association between planning and financial facts, never a foreign key.
public struct FinancialPeriodKey: Hashable, Sendable {
    public let ownerID: String
    public let categoryID: String
    public let month: Int
    public init(ownerID: String, categoryID: String, month: Int) {
        self.ownerID = ownerID
        self.categoryID = categoryID
        self.month = month
    }
}

extension Budget {
    public var periodKey: FinancialPeriodKey {
        FinancialPeriodKey(ownerID: user.id, categoryID: category.id, month: date)
    }
}

extension Transaction {
    public func periodKey(in month: Int) -> FinancialPeriodKey {
        FinancialPeriodKey(ownerID: ownerID, categoryID: category.id, month: month)
    }
    public var billingMonths: [Int] {
        let start = billingStartMonth ?? date.yearMonth
        let startIndex = start / 100 * 12 + start % 100 - 1
        return (0..<min(max(paymentsPlan ?? 1, 1), 1200)).map { offset in
            let index = startIndex + offset
            return index / 12 * 100 + index % 12 + 1
        }
    }
}
