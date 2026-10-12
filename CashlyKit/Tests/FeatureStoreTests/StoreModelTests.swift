import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
struct StoreModelTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")

    private func store(withUser: Bool = true) async throws -> (
        StoreModel, FakeStoreClient, CashlyDatabase
    ) {
        let database = try CashlyDatabase.open(inMemory: true)
        if withUser { try await database.repositories(for: nil).users.save(owner) }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let client = FakeStoreClient()
        let store = StoreModel(session: session, client: client)
        await store.loadProducts()
        await store.refresh()
        return (store, client, database)
    }

    private func events(_ database: CashlyDatabase) async throws -> [GameEvent] {
        try await database.repositories(for: owner.id).game.events()
    }

    @Test func everyCatalogItemHasAProduct() async throws {
        let (store, _, _) = try await store()
        #expect(store.products.count == ShopItem.allCases.count)
        #expect(store.hasLoaded)
        #expect(store.price(for: .iconsAll) == "R$ 9,90")
        #expect(store.entitlement == .none)
    }

    @Test func refreshMarksTheFirstCheckAndDescribesThePlan() async throws {
        let (store, client, _) = try await store()
        #expect(store.hasRefreshed)
        #expect(store.entitlement.title == "Not Subscribed")
        #expect(store.entitlement.detail == nil)
        let ends = Date(timeIntervalSince1970: 1_800_000_000)
        client.deliver(
            StoreTransaction(
                id: 7, productID: ShopItem.proMonthly.id, expirationDate: ends, isFreeTrial: true))
        await store.refresh()
        #expect(store.entitlement == .trial(expires: ends))
        #expect(store.entitlement.title == "Free Trial")
        #expect(store.entitlement.detail?.contains("2027") == true)
    }

    @Test func buyingAnIconPackOwnsIt() async throws {
        let (store, client, _) = try await store()
        client.next = .success(StoreTransaction(id: 1, productID: ShopItem.iconsFashion.id))
        #expect(try await store.purchase(.iconsFashion) == .purchased)
        #expect(store.owned == [.iconsFashion])
        #expect(client.finished == [1])
    }

    @Test func pendingAndCancelledPurchasesOwnNothing() async throws {
        let (store, client, _) = try await store()
        client.next = .pending
        #expect(try await store.purchase(.sounds) == .pending)
        client.next = .cancelled
        #expect(try await store.purchase(.sounds) == .cancelled)
        #expect(store.owned.isEmpty)
        #expect(client.finished.isEmpty)
    }

    @Test func refundedItemsAreNotOwned() async throws {
        let (store, client, _) = try await store()
        client.deliver(StoreTransaction(id: 2, productID: ShopItem.sounds.id, revocationDate: .now))
        await store.refresh()
        #expect(store.owned.isEmpty)
    }

    @Test func freezesAreCreditedOnce() async throws {
        let (store, client, database) = try await store()
        let transaction = StoreTransaction(id: 3, productID: ShopItem.freezes3.id, quantity: 2)
        client.next = .success(transaction)
        _ = try await store.purchase(.freezes3)
        await store.handle(transaction)
        let credited = try await events(database).filter { $0.kind == .freezesCredited }
        #expect(credited.map(\.count) == [6])
        #expect(credited.first?.value == "3")
        #expect(client.finished == [3, 3])
    }

    @Test func consumableWaitsForAProfile() async throws {
        let (store, client, database) = try await store(withUser: false)
        let transaction = StoreTransaction(id: 4, productID: ShopItem.streakRestore.id)
        client.waiting = [transaction]
        await store.handle(transaction)
        #expect(client.finished.isEmpty)
        try await database.repositories(for: nil).users.save(owner)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let readyClient = FakeStoreClient()
        readyClient.waiting = [transaction]
        await StoreModel(session: session, client: readyClient).handle(transaction)
        #expect(readyClient.finished == [4])
        #expect(try await events(database).map(\.kind) == [.streakRestored])
    }

    @Test func subscriptionStartsAsTrialThenRenewsThenExpires() async throws {
        let (store, client, _) = try await store()
        let week = Date.now.addingTimeInterval(7 * 86_400)
        client.next = .success(
            StoreTransaction(
                id: 5, productID: ShopItem.proMonthly.id, expirationDate: week, isFreeTrial: true))
        _ = try await store.purchase(.proMonthly)
        #expect(store.entitlement == .trial(expires: week))
        #expect(store.entitlement.canWrite)
        let month = week.addingTimeInterval(30 * 86_400)
        client.entitlements = [
            StoreTransaction(id: 6, productID: ShopItem.proMonthly.id, expirationDate: month)
        ]
        await store.refresh()
        #expect(store.entitlement == .active(expires: month))
        client.entitlements = []
        client.latestByProduct[ShopItem.proMonthly.id] = StoreTransaction(
            id: 6, productID: ShopItem.proMonthly.id, expirationDate: month)
        await store.refresh()
        #expect(store.entitlement == .expired(month))
        #expect(!store.entitlement.canWrite)
    }

    @Test func restoreSyncsAndRefreshes() async throws {
        let (store, client, _) = try await store()
        client.entitlements = [StoreTransaction(id: 7, productID: ShopItem.iconsAll.id)]
        try await store.restore()
        #expect(client.synced)
        #expect(store.owned == [.iconsAll])
    }
}
