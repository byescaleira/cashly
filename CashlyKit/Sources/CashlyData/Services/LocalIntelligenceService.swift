import CashlyDomain
import Foundation

/// Monthly mean estimators and a multinomial Naive Bayes text classifier.
/// Persists training data per user; models are built and used on this actor.
public actor LocalIntelligenceService: IntelligenceUseCase {
    private struct Model: Codable {
        var info: [IntelligenceModelInfo]
        var budgets: [String: [Int: Double]]
        var tags: [String: [Int: Double]]
        var labels: [String: Int]
        var tokens: [String: [String: Int]]
    }
    private let directory: URL
    private var cache: [String: Model] = [:]
    public init(directory: URL? = nil) {
        self.directory =
            directory
            ?? URL.applicationSupportDirectory.appending(
                path: "Cashly/Intelligence", directoryHint: .isDirectory)
    }
    private func url(for userID: String) -> URL {
        // Persisted user IDs are UUIDs; encoding also prevents arbitrary path traversal.
        let key = Data(userID.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_")
        return directory.appending(path: key + ".json")
    }
    private func model(userID: String) throws -> Model? {
        if let model = cache[userID] { return model }
        let url = url(for: userID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let model = try JSONDecoder().decode(Model.self, from: Data(contentsOf: url))
        cache[userID] = model
        return model
    }
    public func models(userID: String) throws -> [IntelligenceModelInfo] {
        try model(userID: userID)?.info ?? []
    }
    public func train(
        userID: String, transactions: [CashlyDomain.Transaction], tags: [Tag], revision: String
    ) throws
        -> [IntelligenceModelInfo]
    {
        let records = transactions.filter {
            $0.ownerID == userID && $0.kind == .expense && $0.status != .canceled
                && $0.amount.isFinite
        }
        guard records.count >= 2 else {
            throw CashlyError.intelligence(
                "São necessárias pelo menos duas transações para criar estimativas.")
        }
        var model = Model(info: [], budgets: [:], tags: [:], labels: [:], tokens: [:])
        for record in records {
            try Task.checkCancellation()
            let category = record.category.id
            let start = record.billingStartMonth ?? record.date.yearMonth
            let months = (0..<min(max(record.paymentsPlan ?? 1, 1), 1200)).map { offset in
                let index = start / 100 * 12 + start % 100 - 1 + offset
                return index / 12 * 100 + index % 12 + 1
            }
            for month in months {
                model.budgets[category, default: [:]][month, default: 0] +=
                    record.billingMoney(in: month).doubleValue
            }
            model.labels[category, default: 0] += 1
            for token in tokenize(record.summary) {
                model.tokens[category, default: [:]][token, default: 0] += 1
            }
            for tag in tags
            where tag.user.id == userID && record.tagIDs.contains(tag.id) {
                for month in months {
                    model.tags[tag.id, default: [:]][month, default: 0] +=
                        record.billingMoney(in: month).doubleValue
                }
            }
        }
        let eligible = CashlyIntelligence.allCases.filter { kind in
            switch kind {
            case .budgetValue: return model.budgets.values.contains { $0.count >= 2 }
            case .tagValue: return model.tags.values.contains { $0.count >= 2 }
            case .categoryName:
                return model.labels.count >= 2 && model.tokens.values.allSatisfy { !$0.isEmpty }
            }
        }
        guard !eligible.isEmpty else {
            throw CashlyError.intelligence(
                "Histórico insuficiente: use pelo menos duas categorias com descrições ou dois meses registrados."
            )
        }
        model.info = eligible.map {
            .init(kind: $0, updateDate: .now, sampleCount: records.count, datasetRevision: revision)
        }
        let data = try JSONEncoder().encode(model)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url(for: userID), options: .atomic)
        cache[userID] = model
        return model.info
    }
    public func clean(userID: String) throws {
        let url = url(for: userID)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        cache[userID] = nil
    }
    public func predict(userID: String, input: CashlyPredictionInput, revision: String) throws
        -> CashlyPredictionResult
    {
        guard let model = try model(userID: userID),
            model.info.allSatisfy({ $0.datasetRevision == revision })
        else { return .empty }
        switch input {
        case .empty: return .empty
        case .budget(let month, let category):
            guard model.info.contains(where: { $0.kind == .budgetValue }) else { return .empty }
            return estimate(model.budgets[category], before: month)
        case .tag(let month, let name):
            guard model.info.contains(where: { $0.kind == .tagValue }) else { return .empty }
            return estimate(model.tags[name], before: month)
        case .text(let text):
            guard model.info.contains(where: { $0.kind == .categoryName }) else { return .empty }
            let words = tokenize(text)
            let vocabulary = Set(model.tokens.values.flatMap { $0.keys })
            guard words.contains(where: { vocabulary.contains($0) }) else { return .empty }
            let total = Double(model.labels.values.reduce(0, +))
            var best: (String, Double)?
            for label in model.labels.keys.sorted() {
                let frequencies = model.tokens[label, default: [:]]
                let denominator = Double(frequencies.values.reduce(0, +) + max(vocabulary.count, 1))
                var score = log(Double(model.labels[label, default: 1]) / max(total, 1))
                for word in words {
                    score += log(Double(frequencies[word, default: 0] + 1) / denominator)
                }
                if score > (best?.1 ?? -.infinity) { best = (label, score) }
            }
            return best.map { .textClassification($0.0) } ?? .empty
        }
    }
    private func estimate(_ history: [Int: Double]?, before month: Int) -> CashlyPredictionResult {
        guard let history else { return .empty }
        let recent = history.filter { $0.key < month }.sorted { $0.key > $1.key }.prefix(6)
        guard recent.count >= 2 else { return .empty }
        return .tabularRegression(recent.reduce(0) { $0 + $1.value } / Double(recent.count))
    }
    private func tokenize(_ text: String) -> [String] {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 1 }
    }
}
