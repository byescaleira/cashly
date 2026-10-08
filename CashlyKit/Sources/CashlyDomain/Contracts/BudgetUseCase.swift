public protocol BudgetUseCase: Sendable {
    func getBudget(id: String) async throws -> Budget?
    func removeBudget(id: String) async throws
    func addBudget(id: String, money: Money, category: Category, month: YearMonth, summary: String)
        async throws
}
