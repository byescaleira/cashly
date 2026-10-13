import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
struct StoreSimulationTests {
    private func makeStore(defaults: UserDefaults) async throws -> (StoreModel, FakeStoreClient) {
        let database = try CashlyDatabase.open(inMemory: true)
        let session = SessionModel(provider: database, preference: .disabled)
        let client = FakeStoreClient()
        client.deliver(StoreTransaction(id: 1, productID: ShopItem.iconsAll.id))
        let store = StoreModel(session: session, client: client, defaults: defaults)
        await store.refresh()
        return (store, client)
    }

    @Test func simulationOverridesTheStoreWithoutTouchingIt() async throws {
        let suite = "cashly.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (store, _) = try await makeStore(defaults: defaults)
        #expect(!store.isSimulating)
        #expect(store.simulatedPlan == .real)
        #expect(store.entitlement == .none)
        #expect(store.owned == [.iconsAll])

        store.simulatedPlan = .trial
        guard case .trial(let expires) = store.entitlement else {
            Issue.record("expected a trial")
            return
        }
        #expect(expires > .now)
        #expect(store.owned == [.iconsAll])

        store.simulatedPlan = .pro
        store.simulate(.iconsFashion, owned: true)
        store.simulate(.iconsAll, owned: false)
        await store.refresh()
        #expect(store.entitlement.isActive)
        #expect(store.owned == [.iconsFashion])
        #expect(store.storeEntitlement == .none)
        #expect(store.storeOwned == [.iconsAll])
        #expect(store.simulatedOwnedSummary == "1 of \(StoreModel.simulatedItems.count)")

        let (restored, _) = try await makeStore(defaults: defaults)
        #expect(restored.simulatedPlan == .pro)
        #expect(restored.owned == [.iconsFashion])

        restored.simulatedPlan = .real
        #expect(!restored.isSimulating)
        #expect(restored.entitlement == .none)
        #expect(restored.owned == [.iconsAll])
        let keys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("cashly.developer.")
        }
        #expect(keys.isEmpty)
    }
}
