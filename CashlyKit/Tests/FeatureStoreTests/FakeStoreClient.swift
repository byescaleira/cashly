import CashlyDomain
import Foundation

@testable import FeatureStore

@MainActor
final class FakeStoreClient: StoreClient, @unchecked Sendable {
    var catalog = ShopItem.allCases.map { StoreProduct(id: $0.id, displayPrice: "R$ 9,90") }
    var eligible: Set<String> = []
    var entitlements: [StoreTransaction] = []
    var past: [StoreTransaction] = []
    var latestByProduct: [String: StoreTransaction] = [:]
    var waiting: [StoreTransaction] = []
    var finished: [UInt64] = []
    var next: StorePurchase = .cancelled
    var synced = false
    nonisolated let updates: AsyncStream<StoreTransaction>
    private let continuation: AsyncStream<StoreTransaction>.Continuation

    init() {
        (updates, continuation) = AsyncStream.makeStream()
    }

    func deliver(_ transaction: StoreTransaction) {
        latestByProduct[transaction.productID] = transaction
        if ShopItem(rawValue: transaction.productID)?.kind != .consumable {
            entitlements.append(transaction)
        }
    }

    func products(for ids: [String]) async throws -> [StoreProduct] {
        catalog.filter { ids.contains($0.id) }
    }

    func isEligibleForIntroOffer(_ id: String) async -> Bool { eligible.contains(id) }

    func purchase(_ id: String) async throws -> StorePurchase {
        if case .success(let transaction) = next { deliver(transaction) }
        return next
    }

    func currentEntitlements() async -> [StoreTransaction] { entitlements }

    func history() async -> [StoreTransaction] { past }

    func latest(for id: String) async -> StoreTransaction? { latestByProduct[id] }

    func unfinished() async -> [StoreTransaction] { waiting }

    func finish(_ transaction: StoreTransaction) async {
        finished.append(transaction.id)
        waiting.removeAll { $0.id == transaction.id }
    }

    func sync() async throws { synced = true }
}
