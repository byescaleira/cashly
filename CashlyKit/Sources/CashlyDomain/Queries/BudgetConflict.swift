public struct BudgetConflict: Hashable, Identifiable, Sendable {
    public let categoryID: String
    public let month: YearMonth
    public let budgets: [Budget]

    public var id: String { categoryID + "." + String(month.rawValue) }

    public init(categoryID: String, month: YearMonth, budgets: [Budget]) {
        self.categoryID = categoryID
        self.month = month
        self.budgets = budgets
    }
}
