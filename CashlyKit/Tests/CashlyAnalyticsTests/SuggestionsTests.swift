import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct SuggestionsTests {
    private let owner = User(id: "owner", name: "Ana")
    private let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)

    private func category(_ id: String) -> CashlyDomain.Category {
        CashlyDomain.Category(id: id, user: owner, name: id, color: "C2602A", icon: "cart")
    }

    private func transaction(
        _ id: String, _ category: String, _ cents: Int64, months: Int, summary: String,
        kind: TransactionKind = .expense
    ) -> Transaction {
        Transaction(
            id: id, participants: [], category: self.category(category),
            money: Money(minorUnits: cents), date: october.adding(months: months).startDate,
            summary: summary, status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil,
            kind: kind)
    }

    private func suggestions(_ transactions: [Transaction]) -> Suggestions {
        Suggestions(
            ledger: LedgerSnapshot(
                transactions: transactions, categories: [], tags: [], budgets: [], revision: "r1",
                today: october.startDate))
    }

    @Test func budgetIsTheMedianOfRecentMonthsBeforeTheChosenOne() {
        let value = suggestions([
            transaction("a", "market", 30_000, months: -1, summary: "Feira"),
            transaction("b", "market", 50_000, months: -2, summary: "Feira"),
            transaction("c", "market", 10_000, months: -3, summary: "Feira"),
            transaction("d", "market", 99_000, months: 0, summary: "Feira"),
        ])
        #expect(value.budget(categoryID: "market", month: october) == 30_000)
    }

    @Test func budgetNeedsTwoMonthsOfHistory() {
        let value = suggestions([transaction("a", "market", 30_000, months: -1, summary: "Feira")])
        #expect(!value.canSuggestBudget)
        #expect(value.budget(categoryID: "market", month: october) == nil)
    }

    @Test func categoryComesFromSimilarDescriptions() {
        let value = suggestions([
            transaction("a", "market", 5_000, months: -1, summary: "Feira do bairro"),
            transaction("b", "transport", 500, months: -1, summary: "Ônibus centro"),
        ])
        #expect(value.canSuggestCategory)
        #expect(value.category(for: "feira livre") == "market")
        #expect(value.category(for: "onibus") == "transport")
        #expect(value.category(for: "cinema") == nil)
    }

    @Test func incomeIsIgnored() {
        let value = suggestions([
            transaction("a", "salary", 500_000, months: -1, summary: "Salário", kind: .income),
            transaction("b", "salary", 500_000, months: -2, summary: "Salário", kind: .income),
            transaction("c", "market", 5_000, months: -1, summary: "Feira"),
        ])
        #expect(!value.canSuggestBudget)
        #expect(!value.canSuggestCategory)
    }
}

struct ClassifierEvaluationTests {
    @Test func accuracyTrainsOnTheOldestAndTestsOnTheNewest() throws {
        let examples = (0..<20).map {
            CategoryExample(
                text: $0 < 16 ? "Feira" : "Ônibus", categoryID: $0 < 16 ? "market" : "transport",
                date: Date(timeIntervalSince1970: Double($0) * 86_400))
        }
        let accuracy = try #require(
            ClassifierEvaluation.accuracy(examples) { NaiveBayesClassifier(examples: $0) })
        #expect(accuracy == 0)
        #expect(ClassifierEvaluation.accuracy(Array(examples.prefix(8))) { _ in nil } == nil)
    }
}
