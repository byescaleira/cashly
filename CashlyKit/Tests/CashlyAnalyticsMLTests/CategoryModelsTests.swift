import CashlyAnalytics
import CashlyAnalyticsML
import Foundation
import NaturalLanguage
import Testing

private struct Constant: CategoryClassifying {
    let id: String
    func category(for text: String) -> String? { id }
}

struct CategoryModelsTests {
    private func examples(_ count: Int) -> [CategoryExample] {
        (0..<count).map {
            CategoryExample(
                text: $0.isMultiple(of: 2) ? "Uber centro" : "Mercado do bairro",
                categoryID: $0.isMultiple(of: 2) ? "transport" : "market",
                date: Date(timeIntervalSince1970: Double($0) * 86_400))
        }
    }

    @Test func theMoreAccurateCandidateWins() throws {
        let candidates = [
            CategoryCandidate("always-market") { _ in Constant(id: "market") },
            CategoryCandidate("naive-bayes") { NaiveBayesClassifier(examples: $0) },
        ]
        let choice = try #require(CategoryModels.best(for: examples(40), candidates: candidates))
        #expect(choice.name == "naive-bayes")
        #expect(choice.accuracy == 1)
    }

    @Test func fewExamplesStillTrainTheFirstCandidateThatWorks() throws {
        let candidates = [CategoryCandidate("naive-bayes") { NaiveBayesClassifier(examples: $0) }]
        let choice = try #require(CategoryModels.best(for: examples(6), candidates: candidates))
        #expect(choice.accuracy == nil)
        #expect(choice.classifier.category(for: "uber") == "transport")
    }

    @Test(.enabled(if: NLEmbedding.sentenceEmbedding(for: .english) != nil))
    func sentenceEmbeddingsFindTheClosestMeaning() throws {
        let training = [
            ("lunch at a restaurant", "food"), ("dinner with friends", "food"),
            ("pizza delivery", "food"), ("bus ticket", "transport"), ("taxi ride", "transport"),
            ("train fare", "transport"),
        ].enumerated().map {
            CategoryExample(
                text: $1.0, categoryID: $1.1, date: Date(timeIntervalSince1970: Double($0)))
        }
        let space = try #require(
            EmbeddingSpace(texts: training.map(\.text), language: .english))
        let classifier = try #require(EmbeddingClassifier(examples: training, space: space))
        #expect(classifier.category(for: "breakfast at a cafe") == "food")
        #expect(classifier.category(for: "subway ticket") == "transport")
    }
}
