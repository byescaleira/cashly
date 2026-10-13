import Foundation

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public struct BudgetLine: Codable, Equatable, Sendable {
        public let id: String
        public let categoryName: String
        public let color: String
        public let icon: String
        public let plannedMinorUnits: Int64
        public let spentMinorUnits: Int64

        public init(
            id: String, categoryName: String, color: String, icon: String,
            plannedMinorUnits: Int64, spentMinorUnits: Int64
        ) {
            self.id = id
            self.categoryName = categoryName
            self.color = color
            self.icon = icon
            self.plannedMinorUnits = plannedMinorUnits
            self.spentMinorUnits = spentMinorUnits
        }

        public var remainingMinorUnits: Int64 { plannedMinorUnits - spentMinorUnits }
    }

    public struct Bill: Codable, Equatable, Sendable {
        public let id: String
        public let summary: String
        public let amountMinorUnits: Int64
        public let date: Date
        public let icon: String
        public let color: String

        public init(
            id: String, summary: String, amountMinorUnits: Int64, date: Date, icon: String,
            color: String
        ) {
            self.id = id
            self.summary = summary
            self.amountMinorUnits = amountMinorUnits
            self.date = date
            self.icon = icon
            self.color = color
        }
    }

    public let userID: String
    public let userName: String
    public let year: Int
    public let month: Int
    public let currencyCode: String
    public let plannedMinorUnits: Int64
    public let spentMinorUnits: Int64
    public let incomeMinorUnits: Int64
    public let transactionCount: Int
    public let budgets: [BudgetLine]
    public var bills: [Bill]
    public let generatedAt: Date

    public init(
        userID: String, userName: String, month: YearMonth, currencyCode: String,
        plannedMinorUnits: Int64, spentMinorUnits: Int64, incomeMinorUnits: Int64,
        transactionCount: Int = 0, budgets: [BudgetLine], bills: [Bill] = [],
        generatedAt: Date = .now
    ) {
        self.userID = userID
        self.userName = userName
        year = month.year
        self.month = month.month
        self.currencyCode = currencyCode
        self.plannedMinorUnits = plannedMinorUnits
        self.spentMinorUnits = spentMinorUnits
        self.incomeMinorUnits = incomeMinorUnits
        self.transactionCount = transactionCount
        self.budgets = budgets
        self.bills = bills
        self.generatedAt = generatedAt
    }

    public var yearMonth: YearMonth? { YearMonth(year: year, month: month) }
    public var availableMinorUnits: Int64 { plannedMinorUnits - spentMinorUnits }
}

extension WidgetSnapshot {
    public init(
        user: User, month: YearMonth, overview: CashlyOverview, pending: [Transaction] = [],
        currencyCode: String, generatedAt: Date = .now
    ) {
        let lines = overview.budgets.map { budget in
            BudgetLine(
                id: budget.id, categoryName: budget.category.name, color: budget.category.color,
                icon: budget.category.icon, plannedMinorUnits: budget.money.minorUnits,
                spentMinorUnits: overview.budgetExpenses[budget.id]?.minorUnits ?? 0)
        }
        self.init(
            userID: user.id, userName: user.name, month: month, currencyCode: currencyCode,
            plannedMinorUnits: overview.budgetsTotal.minorUnits,
            spentMinorUnits: overview.expensesTotal.minorUnits,
            incomeMinorUnits: overview.incomeTotal.minorUnits,
            transactionCount: overview.transactionCount, budgets: lines,
            bills: pending.sorted { $0.date < $1.date }.prefix(5).map {
                Bill(
                    id: $0.id, summary: $0.summary.isEmpty ? $0.category.name : $0.summary,
                    amountMinorUnits: $0.money.minorUnits, date: $0.date, icon: $0.category.icon,
                    color: $0.category.color)
            }, generatedAt: generatedAt)
    }
}
