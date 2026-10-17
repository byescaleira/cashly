import CashlyAnalytics
import Foundation
import NaturalLanguage

public struct CategoryCandidate: Sendable {
    public let name: String
    public let train: @Sendable ([CategoryExample]) -> (any CategoryClassifying)?

    public init(
        _ name: String, train: @escaping @Sendable ([CategoryExample]) -> (any CategoryClassifying)?
    ) {
        self.name = name
        self.train = train
    }
}

public enum CategoryModels {
    public struct Choice: Sendable {
        public let classifier: any CategoryClassifying
        public let name: String
        public let accuracy: Double?
    }

    public static let limit = 1_500

    public static func best(for examples: [CategoryExample], candidates: [CategoryCandidate]? = nil)
        -> Choice?
    {
        let recent = Array(examples.sorted { $0.date > $1.date }.prefix(limit))
        let all = candidates ?? standard(for: recent)
        var scored: [(candidate: CategoryCandidate, accuracy: Double?)] = []
        for candidate in all {
            if Task.isCancelled { return nil }
            scored.append(
                (candidate, ClassifierEvaluation.accuracy(recent, train: candidate.train)))
        }
        for entry in scored.sorted(by: { ($0.accuracy ?? -1) > ($1.accuracy ?? -1) }) {
            if Task.isCancelled { return nil }
            if let classifier = entry.candidate.train(recent) {
                return Choice(
                    classifier: classifier, name: entry.candidate.name, accuracy: entry.accuracy)
            }
        }
        return nil
    }

    static func standard(for examples: [CategoryExample]) -> [CategoryCandidate] {
        let space = EmbeddingSpace(
            texts: examples.map(\.text), language: dominantLanguage(examples.map(\.text)))
        return [
            CategoryCandidate("naive-bayes") { examples in
                let classifier = NaiveBayesClassifier(examples: examples)
                return classifier.canClassify ? classifier : nil
            },
            CategoryCandidate("sentence-embedding") { examples in
                space.flatMap { EmbeddingClassifier(examples: examples, space: $0) }
            },
        ]
    }

    static func dominantLanguage(_ texts: [String]) -> NLLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [
            .portuguese, .english, .spanish, .german, .french, .italian,
        ]
        recognizer.processString(texts.prefix(300).joined(separator: ". "))
        return recognizer.dominantLanguage ?? .portuguese
    }
}
