import Foundation

public protocol Analysis: Sendable {
    static var id: AnalysisID { get }
    static var title: String { get }
    static var detail: String { get }
    static var version: Int { get }
    init()
    func run(_ ledger: LedgerSnapshot) -> AnalysisResult?
}

extension Analysis {
    func provenance(
        _ ledger: LedgerSnapshot, method: String, confidence: Provenance.Confidence,
        evidence: [String] = []
    ) -> Provenance {
        Provenance(
            method: method, version: Self.version, revision: ledger.revision,
            confidence: confidence,
            evidence: Array(evidence.prefix(20)))
    }

    func result(
        _ ledger: LedgerSnapshot, summary: String, metrics: [Metric], series: [SeriesPoint] = [],
        findings: [Finding] = [], method: String, confidence: Provenance.Confidence,
        evidence: [String] = []
    ) -> AnalysisResult {
        AnalysisResult(
            id: Self.id, title: Self.title, summary: summary, metrics: metrics, series: series,
            findings: findings,
            provenance: provenance(
                ledger, method: method, confidence: confidence, evidence: evidence))
    }
}
