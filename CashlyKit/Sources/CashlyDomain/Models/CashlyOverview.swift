import Foundation

public struct CashlyOverview: Sendable {
    public var budgets: [Budget] = []
    public var budgetsByCategory: [String: [Budget]] = [:]
    public var budgetAmounts: [String: Money] = [:]
    public var categoryExpenses: [String: Money] = [:]
    public var budgetExpenses: [String: Money] = [:]
    public var tagExpenses: [String: Money] = [:]
    public var budgetsTotal: Money = .zero
    public var expensesTotal: Money = .zero
    public var incomeTotal: Money = .zero
    public var netTotal: Money = .zero
    public var transactionCount = 0
    public var expenseDayCount = 0
    public var participantUsers: [User] = []
    public var biggestTransactions: [Transaction] = []
    public var pendingReferences = 0
    public var conflicts: [BudgetConflict] = []
    public init() {}
}

public struct DashboardState: Sendable {
    public let catalog: CashlySnapshot
    public let overview: CashlyOverview
    public let page: TransactionPage
    public let datasetRevision: String
    public let totalTransactionCount: Int
    public init(
        catalog: CashlySnapshot, overview: CashlyOverview, page: TransactionPage,
        datasetRevision: String, totalTransactionCount: Int
    ) {
        self.catalog = catalog
        self.overview = overview
        self.page = page
        self.datasetRevision = datasetRevision
        self.totalTransactionCount = totalTransactionCount
    }
}
