import CashlyAnalytics
import CashlyDomain
import Foundation

public protocol GameSource: Sendable {
    func snapshot(today: Date) async throws -> GameSnapshot
}

public struct RepositoriesGameSource: GameSource {
    private let repositories: Repositories
    private let guideCount: Int

    public init(repositories: Repositories, guideCount: Int) {
        self.repositories = repositories
        self.guideCount = guideCount
    }

    public func snapshot(today: Date) async throws -> GameSnapshot {
        let data = try await repositories.dashboard.trainingData()
        let catalog = try await repositories.dashboard.snapshot(month: nil)
        let events = try await repositories.game.events()
        let ledger = LedgerSnapshot(
            transactions: data.transactions, categories: catalog.categories, tags: catalog.tags,
            budgets: catalog.budgets, revision: data.revision, today: today)
        return GameSnapshot(
            userID: repositories.userID ?? "", ledger: ledger, transactions: data.transactions,
            events: events, guideCount: guideCount)
    }
}
