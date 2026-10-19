import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
enum ProStoreFixture {
    static func store(scheduler: FakeScheduler) async throws -> (StoreModel, FakeStoreClient) {
        let database = try CashlyDatabase.open(inMemory: true)
        let session = SessionModel(provider: database, preference: .disabled)
        let client = FakeStoreClient()
        client.catalog = [
            StoreProduct(
                id: ShopItem.proMonthly.id, displayPrice: "R$ 14,90", price: 14.90,
                period: .month, trialDays: 7),
            StoreProduct(
                id: ShopItem.proYearly.id, displayPrice: "R$ 99,90", price: 99.90, period: .year,
                trialDays: 7),
        ]
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = StoreModel(
            session: session, client: client, defaults: defaults, scheduler: scheduler)
        await store.loadProducts()
        return (store, client)
    }
}
