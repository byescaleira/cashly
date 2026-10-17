import CashlyDomain
import Foundation

public struct Suggestions: Sendable {
    private let monthly: [String: [YearMonth: Int64]]
    private let classifier: NaiveBayesClassifier

    public init(ledger: LedgerSnapshot) {
        var monthly: [String: [YearMonth: Int64]] = [:]
        for posting in ledger.postings where posting.isExpense {
            monthly[posting.categoryID, default: [:]][posting.month, default: 0] +=
                posting.minorUnits
        }
        self.monthly = monthly
        classifier = NaiveBayesClassifier(examples: ledger.categoryExamples)
    }

    public var canSuggestBudget: Bool {
        monthly.values.contains { $0.count >= 2 }
    }

    public var canSuggestCategory: Bool {
        classifier.canClassify
    }

    public func budget(categoryID: String, month: YearMonth) -> Int64? {
        let totals = (1...6).compactMap { monthly[categoryID]?[month.adding(months: -$0)] }
            .filter { $0 > 0 }
        guard totals.count >= 2 else { return nil }
        return BudgetRule.suggested(totals)
    }

    public func category(for text: String) -> String? {
        classifier.category(for: text)
    }
}
