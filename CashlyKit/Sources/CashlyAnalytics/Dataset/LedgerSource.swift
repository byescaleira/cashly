import CashlyDomain
import Foundation

public protocol LedgerSource: Sendable {
    func ledger(today: Date) async throws -> LedgerSnapshot
}

public struct RepositoriesLedgerSource: LedgerSource {
    private let repositories: Repositories

    public init(repositories: Repositories) {
        self.repositories = repositories
    }

    public func ledger(today: Date) async throws -> LedgerSnapshot {
        let data = try await repositories.dashboard.history()
        let catalog = try await repositories.dashboard.snapshot(month: nil)
        return LedgerSnapshot(
            transactions: data.transactions, categories: catalog.categories, tags: catalog.tags,
            budgets: catalog.budgets, revision: data.revision, today: today)
    }
}
