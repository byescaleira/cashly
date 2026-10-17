import CashlyDomain
import Foundation

public protocol CategoryClassifying: Sendable {
    func category(for text: String) -> String?
}

public struct CategoryExample: Hashable, Sendable {
    public let text: String
    public let categoryID: String
    public let date: Date

    public init(text: String, categoryID: String, date: Date) {
        self.text = text
        self.categoryID = categoryID
        self.date = date
    }
}

extension LedgerSnapshot {
    public var categoryExamples: [CategoryExample] {
        postings.filter { $0.isExpense && $0.installment == 1 }
            .filter { !$0.summary.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { CategoryExample(text: $0.summary, categoryID: $0.categoryID, date: $0.date) }
    }
}

public enum ClassifierEvaluation {
    public static func accuracy(
        _ examples: [CategoryExample],
        train: ([CategoryExample]) -> (any CategoryClassifying)?
    ) -> Double? {
        let sorted = examples.sorted { $0.date < $1.date }
        let split = sorted.count * 4 / 5
        let test = sorted[split...]
        guard split >= 10, !test.isEmpty, let classifier = train(Array(sorted[..<split]))
        else { return nil }
        let hits = test.filter { classifier.category(for: $0.text) == $0.categoryID }.count
        return Double(hits) / Double(test.count)
    }
}
