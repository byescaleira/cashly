import Foundation

public actor AnalysisEngine {
    public struct Entry: Sendable {
        public let id: AnalysisID
        public let title: String
        public let detail: String
    }

    public static let standard: [any Analysis.Type] = [
        InstallmentCommitments.self, MonthPace.self, DailyAllowance.self,
        SamePointComparison.self, UnusualCategories.self,
    ]

    private let analyses: [any Analysis.Type]
    private var cache: [String: AnalysisResult] = [:]

    public init(analyses: [any Analysis.Type] = AnalysisEngine.standard) {
        self.analyses = analyses
    }

    public nonisolated var catalog: [Entry] {
        analyses.map { Entry(id: $0.id, title: $0.title, detail: $0.detail) }
    }

    public func run(_ id: AnalysisID, on ledger: LedgerSnapshot) -> AnalysisResult? {
        guard let analysis = analyses.first(where: { $0.id == id }) else { return nil }
        let key = "\(id.rawValue)|\(analysis.version)|\(ledger.fingerprint)"
        if let cached = cache[key] { return cached }
        let result = analysis.init().run(ledger)
        cache[key] = result
        return result
    }

    public func runAll(on ledger: LedgerSnapshot) -> [AnalysisResult] {
        analyses.compactMap { run($0.id, on: ledger) }
    }
}
