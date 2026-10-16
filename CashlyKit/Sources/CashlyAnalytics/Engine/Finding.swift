import Foundation

public struct Recommendation: Hashable, Sendable, Codable {
    public enum Action: String, Sendable, Codable {
        case returnToUsual
    }

    public let action: Action
    public let monthlySaving: Int64

    public init(action: Action, monthlySaving: Int64) {
        self.action = action
        self.monthlySaving = monthlySaving
    }
}

public struct Finding: Hashable, Sendable, Codable, Identifiable {
    public enum Topic: String, Sendable, Codable, CaseIterable {
        case month, spending, saving, upcoming
    }

    public let analysisID: AnalysisID
    public let topic: Topic
    public let subject: String
    public let label: String
    public let summary: String
    public let impact: Int64
    public let metrics: [Metric]
    public let recommendation: Recommendation?
    public let confidence: Provenance.Confidence

    public var id: String { "\(analysisID.rawValue)|\(subject)" }

    public init(
        analysisID: AnalysisID, topic: Topic, subject: String, label: String, summary: String,
        impact: Int64, metrics: [Metric] = [], recommendation: Recommendation? = nil,
        confidence: Provenance.Confidence
    ) {
        self.analysisID = analysisID
        self.topic = topic
        self.subject = subject
        self.label = label
        self.summary = summary
        self.impact = impact
        self.metrics = metrics
        self.recommendation = recommendation
        self.confidence = confidence
    }

    public func metric(_ key: String) -> Metric? {
        metrics.first { $0.key == key }
    }
}
