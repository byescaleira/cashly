import Accelerate
import CashlyAnalytics
import Foundation
import NaturalLanguage

public final class EmbeddingSpace: @unchecked Sendable {
    private let embedding: NLEmbedding
    private let vectors: [String: [Float]]

    public init?(texts: [String], language: NLLanguage) {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language) else { return nil }
        self.embedding = embedding
        var vectors: [String: [Float]] = [:]
        for text in Set(texts.map(Self.normalize)) {
            if Task.isCancelled { return nil }
            if let vector = Self.vector(text, in: embedding) { vectors[text] = vector }
        }
        self.vectors = vectors
    }

    func vector(for text: String) -> [Float]? {
        let key = Self.normalize(text)
        return vectors[key] ?? Self.vector(key, in: embedding)
    }

    static func normalize(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func vector(_ text: String, in embedding: NLEmbedding) -> [Float]? {
        guard let values = embedding.vector(for: text) else { return nil }
        let vector = values.map(Float.init)
        let norm = sqrt(vDSP.sumOfSquares(vector))
        return norm > 0 ? vDSP.divide(vector, norm) : nil
    }
}

public struct EmbeddingClassifier: CategoryClassifying, @unchecked Sendable {
    private let space: EmbeddingSpace
    private let examples: [(vector: [Float], categoryID: String)]
    private let neighbors = 5
    private let minimumSimilarity: Float = 0.5

    public init?(examples: [CategoryExample], space: EmbeddingSpace) {
        self.space = space
        let byText = Dictionary(grouping: examples) { EmbeddingSpace.normalize($0.text) }
        self.examples = byText.compactMap { text, group in
            let counts = Dictionary(grouping: group, by: \.categoryID).mapValues(\.count)
            guard
                let category = counts.max(by: {
                    $0.value == $1.value ? $0.key > $1.key : $0.value < $1.value
                })?.key,
                let vector = space.vector(for: text)
            else { return nil }
            return (vector, category)
        }
        guard Set(self.examples.map(\.categoryID)).count >= 2 else { return nil }
    }

    public func category(for text: String) -> String? {
        guard let vector = space.vector(for: text) else { return nil }
        var nearest: [(similarity: Float, categoryID: String)] = []
        for example in examples {
            let similarity = vDSP.dot(vector, example.vector)
            guard similarity >= minimumSimilarity else { continue }
            if nearest.count < neighbors {
                nearest.append((similarity, example.categoryID))
            } else if let weakest = nearest.indices.min(by: {
                nearest[$0].similarity < nearest[$1].similarity
            }),
                similarity > nearest[weakest].similarity
            {
                nearest[weakest] = (similarity, example.categoryID)
            }
        }
        let votes = Dictionary(grouping: nearest, by: \.categoryID).mapValues {
            $0.reduce(Float(0)) { $0 + $1.similarity }
        }
        return votes.max { $0.value == $1.value ? $0.key > $1.key : $0.value < $1.value }?.key
    }
}
