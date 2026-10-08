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
