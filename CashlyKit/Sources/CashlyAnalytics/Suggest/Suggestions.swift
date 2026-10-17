import CashlyDomain
import Foundation

public struct Suggestions: Sendable {
    private let monthly: [String: [YearMonth: Int64]]
    private let labels: [String: Int]
    private let tokens: [String: [String: Int]]
    private let vocabulary: Set<String>

    public init(ledger: LedgerSnapshot) {
        var monthly: [String: [YearMonth: Int64]] = [:]
        var labels: [String: Int] = [:]
        var tokens: [String: [String: Int]] = [:]
        var seen: Set<String> = []
        for posting in ledger.postings where posting.isExpense {
            monthly[posting.categoryID, default: [:]][posting.month, default: 0] +=
                posting.minorUnits
            guard seen.insert(posting.transactionID).inserted else { continue }
            labels[posting.categoryID, default: 0] += 1
            for token in Self.tokenize(posting.summary) {
                tokens[posting.categoryID, default: [:]][token, default: 0] += 1
            }
        }
        self.monthly = monthly
        self.labels = labels
        self.tokens = tokens
        vocabulary = Set(tokens.values.flatMap(\.keys))
    }

    public var canSuggestBudget: Bool {
        monthly.values.contains { $0.count >= 2 }
    }

    public var canSuggestCategory: Bool {
        labels.count >= 2 && !vocabulary.isEmpty
    }

    public func budget(categoryID: String, month: YearMonth) -> Int64? {
        let totals = (1...6).compactMap { monthly[categoryID]?[month.adding(months: -$0)] }
            .filter { $0 > 0 }
        guard totals.count >= 2 else { return nil }
        return BudgetRule.suggested(totals)
    }

    public func category(for text: String) -> String? {
        let words = Self.tokenize(text)
        guard canSuggestCategory, words.contains(where: vocabulary.contains) else { return nil }
        let total = Double(labels.values.reduce(0, +))
        var best: (id: String, score: Double)?
        for label in labels.keys.sorted() {
            let frequencies = tokens[label, default: [:]]
            let denominator = Double(frequencies.values.reduce(0, +) + vocabulary.count)
            var score = log(Double(labels[label, default: 1]) / total)
            for word in words {
                score += log(Double(frequencies[word, default: 0] + 1) / denominator)
            }
            if score > best?.score ?? -.infinity { best = (label, score) }
        }
        return best?.id
    }

    static func tokenize(_ text: String) -> [String] {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 1 }
    }
}
