import CashlyDomain
import CashlyGame
import Foundation

extension WebSnapshot {
    public struct Context: Sendable {
        public let user: User
        public let today: Date
        public let currency: String
        public let locale: Locale
        public let generatedAt: Date
        public let includesJourney: Bool
        public let guides: Set<String>
        public let unlocks: [Achievement: Date]

        public init(
            user: User, today: Date, currency: String, locale: Locale, generatedAt: Date? = nil,
            includesJourney: Bool = false, guides: Set<String> = [],
            unlocks: [Achievement: Date] = [:]
        ) {
            self.user = user
            self.today = today
            self.currency = currency
            self.locale = locale
            self.generatedAt = generatedAt ?? today
            self.includesJourney = includesJourney
            self.guides = guides
            self.unlocks = unlocks
        }
    }

    public static func make(repositories: Repositories, context: Context) async throws
        -> WebSnapshot
    {
        let month = YearMonth(context.today)
        let dashboard = repositories.dashboard
        let overview = try await dashboard.overview(query: TransactionQuery(month: month))
        let catalog = try await dashboard.snapshot(month: month)
        let recent = try await recentTransactions(dashboard, month: month)
        let pending = try await dashboard.page(
            query: TransactionQuery(month: month, statuses: [.pendingToPay], kinds: [.expense]),
            after: nil, limit: transactionLimit
        ).items
        var snapshot = WebSnapshot(
            context: context, month: month, overview: overview, transactions: recent,
            tags: catalog.tags, pending: pending)
        await snapshot.addSections(
            repositories: repositories, context: context, overview: overview, catalog: catalog)
        return snapshot
    }

    public init(
        context: Context, month: YearMonth, overview: CashlyOverview,
        transactions: [Transaction], tags: [Tag], pending: [Transaction]
    ) {
        let names = Dictionary(
            tags.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let entries = transactions.map { transaction in
            (date: transaction.billingDate(in: month) ?? transaction.date, transaction)
        }
        .sorted { $0.date > $1.date }
        .prefix(Self.transactionLimit)
        .map { date, transaction in
            Entry(
                date: WebDay.string(date), description: Self.description(of: transaction),
                kind: transaction.kind.webName, status: transaction.status.webName,
                amount: transaction.billingMoney(in: month).doubleValue,
                category: Category(transaction.category),
                tags: transaction.tagIDs.compactMap { names[$0] }.sorted())
        }
        let bills = pending.map { transaction in
            (date: transaction.billingDate(in: month) ?? transaction.date, transaction)
        }
        .sorted { $0.date < $1.date }
        .map { date, transaction in
            Bill(
                description: Self.description(of: transaction), dueDate: WebDay.string(date),
                amount: transaction.billingMoney(in: month).doubleValue)
        }
        self.init(
            v: Self.version, generatedAt: context.generatedAt.formatted(.iso8601),
            locale: context.locale.identifier(.bcp47), currency: context.currency,
            profile: Profile(
                name: context.user.name, initials: context.user.initials,
                color: WebPalette.name(for: context.user.photo.color ?? ProfilePhoto.defaultColor)),
            month: Month(
                month: month, today: context.today, planned: overview.budgetsTotal,
                spent: overview.expensesTotal, income: overview.incomeTotal),
            budgets: overview.budgets.map { budget in
                Budget(
                    name: budget.category.name, symbol: budget.category.icon,
                    color: WebPalette.name(for: budget.category.color),
                    planned: budget.money.doubleValue,
                    spent: overview.budgetExpenses[budget.id, default: .zero].doubleValue)
            },
            transactions: Array(entries), upcoming: bills)
    }

    static func recentTransactions(_ dashboard: any DashboardRepository, month: YearMonth)
        async throws -> [Transaction]
    {
        var items: [Transaction] = []
        var cursor: TransactionCursor?
        repeat {
            let page = try await dashboard.page(
                query: TransactionQuery(month: month), after: cursor,
                limit: transactionLimit - items.count)
            items += page.items
            cursor = page.nextCursor
        } while cursor != nil && items.count < transactionLimit
        return items
    }

    static func description(of transaction: Transaction) -> String {
        transaction.summary.isEmpty ? transaction.category.name : transaction.summary
    }
}

extension WebSnapshot.Category {
    init(_ category: CashlyDomain.Category) {
        self.init(
            name: category.name, symbol: category.icon,
            color: WebPalette.name(for: category.color))
    }
}

extension TransactionKind {
    var webName: String {
        switch self {
        case .expense: "expense"
        case .income: "income"
        }
    }
}

extension TransactionStatus {
    var webName: String {
        switch self {
        case .settled: "paid"
        case .pendingToPay: "toPay"
        case .pendingToReceive: "toReceive"
        case .canceled: "canceled"
        }
    }
}
