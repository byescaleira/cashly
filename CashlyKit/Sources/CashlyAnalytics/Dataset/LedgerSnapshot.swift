import CashlyDomain
import Foundation

public struct LedgerSnapshot: Sendable {
    public let postings: [Posting]
    public let categories: [CashlyDomain.Category]
    public let tags: [Tag]
    public let budgets: [Budget]
    public let revision: String
    public let today: Date

    public init(
        postings: [Posting], categories: [CashlyDomain.Category], tags: [Tag], budgets: [Budget],
        revision: String, today: Date = .now
    ) {
        self.postings = postings
        self.categories = categories
        self.tags = tags
        self.budgets = budgets
        self.revision = revision
        self.today = today
    }

    public init(
        transactions: [Transaction], categories: [CashlyDomain.Category], tags: [Tag],
        budgets: [Budget], revision: String, today: Date = .now
    ) {
        self.init(
            postings: transactions.flatMap(\.postings), categories: categories, tags: tags,
            budgets: budgets, revision: revision, today: today)
    }

    public var currentMonth: YearMonth { YearMonth(today) }

    public func postings(in month: YearMonth) -> [Posting] {
        postings.filter { $0.month == month }
    }

    public func budgeted(in month: YearMonth) -> Int64 {
        budgets.filter { $0.month == month }.reduce(0) { $0 + $1.money.minorUnits }
    }

    public func category(id: String) -> CashlyDomain.Category? {
        categories.first { $0.id == id }
    }
}
