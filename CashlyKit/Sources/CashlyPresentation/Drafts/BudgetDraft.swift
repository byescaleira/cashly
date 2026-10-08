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

    public var user: User? {
        category?.user
    }

    public var canSave: Bool {
        amount.isFinite && ((try? Money(validating: amount).minorUnits) ?? 0) > 0 && category != nil
            && summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    public var yearMonth: Int {
        date.timeIntervalSince1970.yearMonth
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

    public static func new() -> BudgetDraft {
        BudgetDraft()
    }

    public static func new(category: CashlyDomain.Category, date: Date) -> BudgetDraft {
        BudgetDraft(category: category, date: date)
    }

    public static func edit(id: String) -> BudgetDraft {
        BudgetDraft(id: id, isNew: false)
    }
}
