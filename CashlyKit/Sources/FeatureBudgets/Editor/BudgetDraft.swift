import CashlyDomain
import Foundation

public struct BudgetDraft: Hashable {
    public var categories: [CashlyDomain.Category]
    public var id: String
    public var amount: Double
    public var category: CashlyDomain.Category?
    public var date: Date
    public var summary: String
    public var isNew: Bool
    public var currencyCode = Money.currencyCode
    public var estimate: CurrencyEstimate?

    public var user: User? {
        category?.user
    }

    public var canSave: Bool {
        amount.isFinite && ((try? Money(validating: amount).minorUnits) ?? 0) > 0 && category != nil
            && summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    public var month: YearMonth {
        YearMonth(date)
    }

    private init(
        categories: [CashlyDomain.Category] = [],
        id: String = UUID().uuidString,
        amount: Double = .zero,
        category: CashlyDomain.Category? = nil,
        date: Date = .now,
        summary: String = "",
        isNew: Bool = true,
    ) {
        self.categories = categories
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
        self.isNew = isNew
    }

    public static func new(date: Date = .now) -> BudgetDraft {
        BudgetDraft(date: date)
    }

    public static func new(category: CashlyDomain.Category, date: Date, amount: Double = 0)
        -> BudgetDraft
    {
        BudgetDraft(amount: amount, category: category, date: date)
    }

    public static func edit(id: String) -> BudgetDraft {
        BudgetDraft(id: id, isNew: false)
    }

    public func makeBudget() throws -> Budget {
        guard canSave, let category else { throw CashlyError.onSave }
        return Budget(
            id: id, money: try Money(validating: amount), category: category, month: month,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            currencyCode: currencyCode, estimate: estimate)
    }

    public mutating func apply(_ budget: Budget?, categories: [CashlyDomain.Category]) {
        self.categories = categories
        if let budget {
            id = budget.id
            amount = budget.money.doubleValue
            category = budget.category
            date = budget.month.startDate
            summary = budget.summary
            currencyCode = budget.currencyCode
            estimate = budget.estimate
        } else {
            category = category ?? categories.first
        }
    }

    public mutating func refresh(categories: [CashlyDomain.Category]) {
        self.categories = categories
        category = categories.first { $0.id == category?.id } ?? categories.first
    }
}
