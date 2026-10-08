import Foundation

public struct IntelligenceModelInfo: Codable, Sendable, Identifiable {
    public let kind: CashlyIntelligence
    public let updateDate: Date
    public let sampleCount: Int
    public let datasetRevision: String?
    public var id: CashlyIntelligence { kind }
    public init(
        kind: CashlyIntelligence, updateDate: Date, sampleCount: Int, datasetRevision: String? = nil
    ) {
        self.kind = kind
        self.updateDate = updateDate
        self.sampleCount = sampleCount
        self.datasetRevision = datasetRevision
    }
}
public enum CashlyPredictionInput: Hashable, Sendable {
    case empty
    case text(String)
    case budget(yearMonth: Int, categoryID: String)
    case tag(yearMonth: Int, tagID: String)
}
public enum CashlyPredictionResult: Equatable, Sendable {
    case empty
    case textClassification(String)
    case tabularRegression(Double)
}
public protocol IntelligenceUseCase: Sendable {
    func models(userID: String) async throws -> [IntelligenceModelInfo]
    func train(userID: String, transactions: [Transaction], tags: [Tag], revision: String)
        async throws
        -> [IntelligenceModelInfo]
    func predict(userID: String, input: CashlyPredictionInput, revision: String) async throws
        -> CashlyPredictionResult
    func clean(userID: String) async throws
}
