import CashlyDomain
import Foundation

extension FinanceModel {
    public func expensesAmount(for category: CashlyDomain.Category) -> Double {
        summary.categoryExpenses[category.id, default: .zero].doubleValue
    }
    public func expensesAmount(for budget: Budget) -> Double {
        summary.budgetExpenses[budget.id, default: .zero].doubleValue
    }
    public func expensesAmount(for tag: Tag) -> Double {
        summary.tagExpenses[tag.id, default: .zero].doubleValue
    }
    public func budgetsAmount(for category: CashlyDomain.Category) -> Double {
        summary.budgetAmounts[category.id, default: .zero].doubleValue
    }
    public func budgets(for category: CashlyDomain.Category) -> [Budget] {
        summary.budgetsByCategory[category.id, default: []]
    }
    public func budget(for category: CashlyDomain.Category) -> Budget? {
        budgets(for: category).first
    }
    public var categoriesWithoutBudgets: [CashlyDomain.Category] {
        categories.filter { category in !budgets.contains { $0.category.id == category.id } }
    }
    public var categoriesWithBudgets: [CashlyDomain.Category] {
        categories.filter { category in budgets.contains { $0.category.id == category.id } }
    }
    public var budgetsAmount: Double { summary.budgetsTotal.doubleValue }
    public var incomeAmount: Double { summary.incomeTotal.doubleValue }
    public var netAmount: Double { summary.netTotal.doubleValue }
    public var expensesAmount: Double { summary.expensesTotal.doubleValue }
    public var remainingAmount: Double {
        Money(minorUnits: summary.budgetsTotal.minorUnits - summary.expensesTotal.minorUnits)
            .doubleValue
    }
    public var usage: BudgetUsage {
        BudgetUsage(spent: summary.expensesTotal, budgeted: summary.budgetsTotal)
    }
    public var variation: Double { usage.ratio }
    public var health: BudgetHealth { BudgetHealth(usage: usage) }
    public var warningCategories: [CashlyDomain.Category] {
        Array(
            categories.filter { categoryUsage(category: $0).isWarning }
                .sorted { categoryVariation(category: $0) > categoryVariation(category: $1) }
                .prefix(5))
    }
    public func categoryUsage(category: CashlyDomain.Category, adding amount: Double = 0)
        -> BudgetUsage
    {
        BudgetUsage(
            spent: expensesAmount(for: category) + amount, budgeted: budgetsAmount(for: category))
    }
    public func categoryVariation(category: CashlyDomain.Category, amount: Double = 0) -> Double {
        categoryUsage(category: category, adding: amount).ratio
    }
    public func categoryRemainingAmount(category: CashlyDomain.Category) -> Double {
        Money(
            minorUnits: summary.budgetAmounts[category.id, default: .zero].minorUnits
                - summary.categoryExpenses[category.id, default: .zero].minorUnits
        ).doubleValue
    }
    public var transactionUsers: [User] { summary.participantUsers }
    public var expensesAverageAmount: Double {
        expensesAmount / Double(max(summary.expenseDayCount, 1))
    }
    public var biggestCategories: [CashlyDomain.Category] {
        Array(categories.sorted { budgetsAmount(for: $0) > budgetsAmount(for: $1) }.prefix(5))
    }
    public var biggestTags: [Tag] {
        Array(tags.sorted { expensesAmount(for: $0) > expensesAmount(for: $1) }.prefix(5))
    }
    public var biggestTransactions: [CashlyDomain.Transaction] { summary.biggestTransactions }
}
