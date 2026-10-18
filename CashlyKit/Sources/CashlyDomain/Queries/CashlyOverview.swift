public struct CashlyOverview: Sendable {
    public var budgets: [Budget] = []
    public var budgetsByCategory: [String: [Budget]] = [:]
    public var budgetAmounts: [String: Money] = [:]
    public var categoryExpenses: [String: Money] = [:]
    public var budgetExpenses: [String: Money] = [:]
    public var tagExpenses: [String: Money] = [:]
    public var tagCounts: [String: Int] = [:]
    public var budgetsTotal: Money = .zero
    public var expensesTotal: Money = .zero
    public var incomeTotal: Money = .zero
    public var netTotal: Money = .zero
    public var transactionCount = 0
    public var convertedCount = 0
    public var expenseDayCount = 0
    public var participantUsers: [User] = []
    public var biggestTransactions: [Transaction] = []
    public var pendingReferences = 0
    public var conflicts: [BudgetConflict] = []

    public init() {}
}
