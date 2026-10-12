import CashlyDomain
import Foundation

public struct IntentActions: Sendable {
    public struct MonthSummary: Equatable, Sendable {
        public let month: YearMonth
        public let spent: Money
        public let planned: Money
        public let income: Money

        public var available: Money { Money(minorUnits: planned.minorUnits - spent.minorUnits) }
    }

    public struct CategoryRemaining: Equatable, Sendable {
        public let category: CashlyDomain.Category
        public let spent: Money
        public let planned: Money?

        public var remaining: Money? {
            planned.map { Money(minorUnits: $0.minorUnits - spent.minorUnits) }
        }
    }

    private let repositories: Repositories
    private let user: User
    private let now: @Sendable () -> Date

    public init(
        repositories: Repositories, user: User, now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repositories = repositories
        self.user = user
        self.now = now
    }

    public func categories() async throws -> [CashlyDomain.Category] {
        try await repositories.dashboard.snapshot(month: nil).categories
            .filter { $0.user.id == user.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func tags() async throws -> [Tag] {
        try await repositories.dashboard.snapshot(month: nil).tags
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func pendingBills(limit: Int = 50) async throws -> [Transaction] {
        try await repositories.dashboard.page(
            query: TransactionQuery(statuses: [.pendingToPay], kinds: [.expense]), after: nil,
            limit: limit
        ).items
    }

    public func addExpense(
        amount: Double, categoryID: String?, summary: String, date: Date?, tagIDs: Set<String> = []
    ) async throws -> Transaction {
        let money = try Money(validating: amount)
        guard money.minorUnits > 0 else {
            throw CashlyError.invalidInput(String(appLocalized: "The amount must be positive."))
        }
        let options = try await categories()
        guard let category = options.first(where: { $0.id == categoryID }) ?? options.first else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Create a category in Cashly before adding expenses."))
        }
        let text = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let transaction = Transaction(
            id: UUID().uuidString, participants: [], category: category, money: money,
            date: date ?? now(), summary: text.count >= 3 ? text : category.name,
            status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil, tagIDs: tagIDs)
        try await repositories.transactions.save(transaction)
        return transaction
    }

    public func monthSummary(month: YearMonth? = nil) async throws -> MonthSummary {
        let month = month ?? YearMonth(now())
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        return MonthSummary(
            month: month, spent: overview.expensesTotal, planned: overview.budgetsTotal,
            income: overview.incomeTotal)
    }

    public func remaining(categoryID: String, month: YearMonth? = nil) async throws
        -> CategoryRemaining
    {
        let month = month ?? YearMonth(now())
        guard let category = try await categories().first(where: { $0.id == categoryID }) else {
            throw CashlyError.missingRecord
        }
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        let planned = overview.budgets.filter { $0.category.id == categoryID }.map(\.money)
        return CategoryRemaining(
            category: category, spent: overview.categoryExpenses[categoryID] ?? .zero,
            planned: planned.isEmpty
                ? nil : Money(minorUnits: planned.map(\.minorUnits).reduce(0, +)))
    }

    public func markPaid(transactionID: String) async throws -> Transaction {
        guard var transaction = try await repositories.transactions.transaction(id: transactionID)
        else { throw CashlyError.missingRecord }
        transaction.status = .settled
        try await repositories.transactions.save(transaction)
        return transaction
    }
}
