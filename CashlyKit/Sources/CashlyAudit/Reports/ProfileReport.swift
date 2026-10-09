import CashlyData
import CashlyDomain
import Foundation

enum ProfileReport {
    @MainActor static func measure(store: URL) async throws -> [String] {
        guard store.lastPathComponent == "benchmark.store" else {
            throw CashlyError.invalidInput(
                "Profile aceita somente benchmark.store gerado pelo diagnóstico.")
        }
        let database = try CashlyDatabase.open(cloudSync: false, storeURL: store)
        let dashboard = database.repositories(for: "a").dashboard
        let query = TransactionQuery(month: try .audit(202601))
        let clock = ContinuousClock()
        var start = clock.now
        let overview = try await dashboard.overview(query: query)
        let overviewTime = start.duration(to: clock.now)
        start = clock.now
        let revision = try await dashboard.datasetRevision()
        let revisionTime = start.duration(to: clock.now)
        start = clock.now
        let page = try await dashboard.page(query: query, after: nil, limit: 50)
        return [
            "PROFILE overview=\(overviewTime) count=\(overview.transactionCount)",
            "PROFILE revision=\(revisionTime) fingerprint=\(revision.prefix(8))",
            "PROFILE firstPage=\(start.duration(to: clock.now)) items=\(page.items.count)",
        ]
    }
}
