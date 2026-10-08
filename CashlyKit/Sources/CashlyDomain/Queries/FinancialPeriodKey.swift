public struct FinancialPeriodKey: Hashable, Sendable {
    public let ownerID: String
    public let categoryID: String
    public let month: YearMonth

    public init(ownerID: String, categoryID: String, month: YearMonth) {
        self.ownerID = ownerID
        self.categoryID = categoryID
        self.month = month
    }
}

extension Budget {
    public var periodKey: FinancialPeriodKey {
        FinancialPeriodKey(ownerID: user.id, categoryID: category.id, month: month)
    }
}

extension Transaction {
    public func periodKey(in month: YearMonth) -> FinancialPeriodKey {
        FinancialPeriodKey(ownerID: ownerID, categoryID: category.id, month: month)
    }
}
