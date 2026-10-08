public struct Budget: Identifiable, Hashable, Sendable {
    public var id: String
    public var money: Money
    public var category: Category
    public var month: YearMonth
    public var summary: String
    public var isConflicted: Bool

    public var user: User { category.user }

    public init(
        id: String, money: Money, category: Category, month: YearMonth, summary: String,
        isConflicted: Bool = false
    ) {
        self.id = id
        self.money = money
        self.category = category
        self.month = month
        self.summary = summary
        self.isConflicted = isConflicted
    }
}
