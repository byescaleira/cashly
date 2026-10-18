import Foundation

public struct OverviewAccumulator {
    private let month: YearMonth?
    private let budgetsByPeriod: [FinancialPeriodKey: [Budget]]
    private var overview = CashlyOverview()
    private var days: Set<Date> = []
    private var periodDays: Set<Int> = []
    private var people: [String: (user: User, money: Money)] = [:]

    public init(
        budgets: [Budget], month: YearMonth?, categoryIDs: Set<String>, pendingReferences: Int
    ) throws {
        self.month = month
        let selected = budgets.filter {
            (month == nil || $0.month == month)
                && (categoryIDs.isEmpty || categoryIDs.contains($0.category.id))
        }
        overview.pendingReferences = pendingReferences
        overview.budgets = selected
        overview.conflicts = BudgetConflict.detect(in: selected)
        let active = selected.filter { !$0.isConflicted }
        for budget in active {
            overview.budgetsTotal = try overview.budgetsTotal.adding(budget.money)
            overview.budgetsByCategory[budget.category.id, default: []].append(budget)
            overview.budgetAmounts[budget.category.id] = try overview.budgetAmounts[
                budget.category.id, default: .zero
            ].adding(budget.money)
        }
        budgetsByPeriod = Dictionary(grouping: active, by: \.periodKey)
    }

    public mutating func addPendingReferences(_ count: Int) {
        overview.pendingReferences += count
    }

    public mutating func add(_ record: Transaction) throws {
        let amount = record.billingMoney(in: month)
        overview.transactionCount += 1
        guard record.kind == .expense else {
            overview.incomeTotal = try overview.incomeTotal.adding(amount)
            return
        }
        overview.expensesTotal = try overview.expensesTotal.adding(amount)
        overview.categoryExpenses[record.category.id] = try overview.categoryExpenses[
            record.category.id, default: .zero
        ].adding(amount)
        for billingMonth in month.map({ [$0] }) ?? record.billingMonths {
            for budget in budgetsByPeriod[record.periodKey(in: billingMonth), default: []] {
                overview.budgetExpenses[budget.id] = try overview.budgetExpenses[
                    budget.id, default: .zero
                ].adding(record.billingMoney(in: billingMonth))
            }
        }
        for id in record.tagIDs {
            overview.tagExpenses[id] = try overview.tagExpenses[id, default: .zero].adding(amount)
            overview.tagCounts[id, default: 0] += 1
        }
        recordDay(of: record)
        guard record.status != .canceled else { return }
        for participant in record.participants {
            let prior = people[participant.user.id]?.money ?? .zero
            people[participant.user.id] = (
                participant.user,
                try prior.adding(record.participantMoney(id: participant.id, in: month))
            )
        }
        overview.biggestTransactions.append(record)
        overview.biggestTransactions.sort {
            let lhs = $0.billingMoney(in: month)
            let rhs = $1.billingMoney(in: month)
            return lhs == rhs ? $0.id < $1.id : lhs > rhs
        }
        if overview.biggestTransactions.count > 5 { overview.biggestTransactions.removeLast() }
    }

    public func result() throws -> CashlyOverview {
        var result = overview
        result.netTotal = try overview.incomeTotal.subtracting(overview.expensesTotal)
        result.expenseDayCount = month == nil ? days.count : periodDays.count
        result.participantUsers = people.values.sorted {
            $0.money == $1.money ? $0.user.id < $1.user.id : $0.money > $1.money
        }
        .prefix(5).map(\.user)
        return result
    }

    private mutating func recordDay(of record: Transaction) {
        let calendar = CashlyCalendar.current
        if let month {
            periodDays.insert(min(calendar.component(.day, from: record.date), month.dayCount))
        } else {
            days.insert(calendar.startOfDay(for: record.date))
        }
    }
}
