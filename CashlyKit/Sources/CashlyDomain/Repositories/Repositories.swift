public struct Repositories: Sendable {
    public let userID: String?
    public let users: any UserRepository
    public let categories: any CategoryRepository
    public let tags: any TagRepository
    public let budgets: any BudgetRepository
    public let transactions: any TransactionRepository
    public let dashboard: any DashboardRepository

    public init(
        userID: String?, users: any UserRepository, categories: any CategoryRepository,
        tags: any TagRepository, budgets: any BudgetRepository,
        transactions: any TransactionRepository, dashboard: any DashboardRepository
    ) {
        self.userID = userID
        self.users = users
        self.categories = categories
        self.tags = tags
        self.budgets = budgets
        self.transactions = transactions
        self.dashboard = dashboard
    }
}
