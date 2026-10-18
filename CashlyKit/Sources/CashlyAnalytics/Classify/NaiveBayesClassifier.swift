import Foundation

public struct NaiveBayesClassifier: CategoryClassifying {
    private let labels: [String: Int]
    private let tokens: [String: [String: Int]]
    private let vocabulary: Set<String>

    public init(examples: [CategoryExample]) {
        var labels: [String: Int] = [:]
        var tokens: [String: [String: Int]] = [:]
        for example in examples {
            labels[example.categoryID, default: 0] += 1
            for token in Self.tokenize(example.text) {
                tokens[example.categoryID, default: [:]][token, default: 0] += 1
            }
        }
        self.labels = labels
        self.tokens = tokens
        vocabulary = Set(tokens.values.flatMap(\.keys))
    }

    public var canClassify: Bool {
        labels.count >= 2 && !vocabulary.isEmpty
    }

    public func category(for text: String) -> String? {
        let words = Self.tokenize(text)
        guard canClassify, words.contains(where: vocabulary.contains) else { return nil }
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
