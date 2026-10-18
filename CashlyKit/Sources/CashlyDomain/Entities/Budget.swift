public struct Budget: Identifiable, Hashable, Sendable {
    public var id: String
    public var money: Money
    public var category: Category
    public var month: YearMonth
    public var summary: String
    public var isConflicted: Bool
    public var currencyCode: String
    public var estimate: CurrencyEstimate?

    public var user: User { category.user }

    public init(
        id: String, money: Money, category: Category, month: YearMonth, summary: String,
        isConflicted: Bool = false, currencyCode: String = Money.currencyCode,
        estimate: CurrencyEstimate? = nil
    ) {
        self.id = id
        self.money = money
        self.category = category
        self.month = month
        self.summary = summary
        self.isConflicted = isConflicted
        self.currencyCode = currencyCode
        self.estimate = estimate
    }

    public var stored: Budget {
        guard let estimate else { return self }
        var value = self
        value.money = estimate.money
        value.currencyCode = estimate.currencyCode
        value.estimate = nil
        return value
    }
}
