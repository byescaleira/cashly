import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
struct ProPlanChangeTests {
    private let day: TimeInterval = 86_400
    private let scheduler = FakeScheduler()

    private func store() async throws -> (StoreModel, FakeStoreClient) {
        try await ProStoreFixture.store(scheduler: scheduler)
    }

    private func isPro(_ client: FakeStoreClient) async throws -> Bool {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        return await ProRule.isPro(isEnforced: true, client: client, defaults: defaults)
    }

    private func eventually(_ condition: () -> Bool) async {
        for _ in 0..<60 where !condition() {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func grace(_ plan: ShopItem = .proYearly) -> ProSubscription {
        ProSubscription(
            state: .inGracePeriod, plan: plan, expirationDate: .now.addingTimeInterval(-day),
            gracePeriodEnd: .now.addingTimeInterval(10 * day), expirationReason: .billingError)
    }

    @Test func gracePeriodIsProInTheWindowAndOutsideIt() async throws {
        let (store, client) = try await store()
        client.entitlements = [
            StoreTransaction(
                id: 1, productID: ShopItem.proYearly.id,
                expirationDate: .now.addingTimeInterval(-day))
        ]
        await store.refresh()
        #expect(store.entitlement.isActive)
        #expect(try await isPro(client))
        client.statuses = [grace()]
        await store.refresh()
        #expect(store.entitlement.isActive)
        #expect(try await isPro(client))
        #expect(store.planTitle == "Active")
        #expect(store.planDetail?.contains("while Apple retries the payment") == true)
        #expect(store.paymentNotice?.title == "Update Payment Method")
        #expect(store.planSwitch == nil)
        #expect(!store.canSubscribe)
    }

    @Test func billingRetryWithoutGraceIsNotPro() async throws {
        let (store, client) = try await store()
        client.statuses = [
            ProSubscription(
                state: .inBillingRetry, plan: .proMonthly,
                expirationDate: .now.addingTimeInterval(-day), expirationReason: .billingError)
        ]
        await store.refresh()
        #expect(!store.entitlement.isActive)
        #expect(try await !isPro(client))
        #expect(store.planTitle == "On Hold")
        #expect(store.isOnHold)
        #expect(store.paymentNotice?.detail.contains("bring Cashly Pro back") == true)
        #expect(!store.canSubscribe)
        #expect(store.planSwitch == nil)
        client.eligible = [ShopItem.proYearly.id, ShopItem.proMonthly.id]
        await store.loadProducts()
        #expect(store.trialDays == nil)
        #expect(store.trialDays(for: .proMonthly) == nil)
        client.statuses = []
        await store.refresh()
        #expect(store.trialDays == 7)
        #expect(!store.isOnHold)
    }

    @Test func revokedAndExpiredAreNotPro() async throws {
        let (store, client) = try await store()
        for state in [ProSubscription.State.revoked, .expired] {
            client.statuses = [
                ProSubscription(
                    state: state, plan: .proYearly, expirationDate: .now.addingTimeInterval(day))
            ]
            await store.refresh()
            #expect(!store.entitlement.isActive)
            #expect(try await !isPro(client))
            #expect(store.canSubscribe)
        }
    }

    @Test func flagAndSimulationDecideBeforeStoreKit() async throws {
        let client = FakeStoreClient()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        #expect(await ProRule.isPro(isEnforced: false, client: client, defaults: defaults))
        #expect(!(await ProRule.isPro(isEnforced: true, client: client, defaults: defaults)))
        StoreSimulation(plan: .gracePeriod, expires: .now.addingTimeInterval(day), owned: [])
            .save(to: defaults)
        #expect(await ProRule.isPro(isEnforced: true, client: client, defaults: defaults))
        StoreSimulation(plan: .billingRetry, expires: .now.addingTimeInterval(-day), owned: [])
            .save(to: defaults)
        client.statuses = [grace()]
        #expect(!(await ProRule.isPro(isEnforced: true, client: client, defaults: defaults)))
    }

    @Test func expiryWhileOpenEndsProAtTheDate() async throws {
        let (store, client) = try await store()
        let ends = Date.now.addingTimeInterval(0.3)
        client.statuses = [
            ProSubscription(
                state: .subscribed, plan: .proMonthly, willRenew: false, expirationDate: ends,
                expirationReason: .cancelled)
        ]
        await store.refresh()
        #expect(store.entitlement.isActive)
        #expect(store.nextCheck == ends)
        await eventually { !store.entitlement.isActive }
        #expect(!store.entitlement.isActive)
        #expect(
            ProAccess(entitlement: store.entitlement, isEnforced: true, present: {}).isPro == false)
        #expect(store.nextCheck == nil)
    }

    @Test func refundAndRenewalChangesArriveWhileListening() async throws {
        let (store, client) = try await store()
        let renews = Date.now.addingTimeInterval(20 * day)
        let transaction = StoreTransaction(
            id: 9, productID: ShopItem.proMonthly.id, expirationDate: renews)
        client.deliver(transaction)
        client.statuses = [
            ProSubscription(state: .subscribed, plan: .proMonthly, expirationDate: renews)
        ]
        let listening = Task { await store.start() }
        defer { listening.cancel() }
        await eventually { store.entitlement.isActive }
        #expect(store.planDetail?.hasPrefix("Renews on") == true)
        client.changeStatus(
            ProSubscription(
                state: .subscribed, plan: .proMonthly, willRenew: false, expirationDate: renews,
                expirationReason: .cancelled))
        await eventually { store.planDetail?.contains("renewal off") == true }
        #expect(store.planDetail?.contains("renewal off") == true)
        #expect(store.entitlement.isActive)
        #expect(store.planSwitch == nil)
        #expect(store.renewalNotice?.title == "Turn On Renewal")
        #expect(store.renewalNotice?.detail == "Keep Cashly Pro after \(Entitlement.day(renews)).")
        client.statuses = [
            ProSubscription(state: .revoked, plan: .proMonthly, expirationDate: renews)
        ]
        client.send(
            StoreTransaction(
                id: 9, productID: ShopItem.proMonthly.id, expirationDate: renews,
                revocationDate: .now))
        await eventually { !store.entitlement.isActive }
        #expect(!store.entitlement.isActive)
        #expect(client.finished.contains(9))
    }

    @Test func approvedAskToBuyClearsThePendingPlan() async throws {
        let (store, client) = try await store()
        client.next = .pending
        #expect(!(await store.buy(.proYearly)))
        #expect(store.isPending)
        #expect(store.isPending(.proYearly))
        let listening = Task { await store.start() }
        defer { listening.cancel() }
        await eventually { store.hasRefreshed }
        client.send(
            StoreTransaction(
                id: 11, productID: ShopItem.proYearly.id,
                expirationDate: .now.addingTimeInterval(365 * day)))
        await eventually { !store.isPending }
        #expect(!store.isPending)
        #expect(!store.isPending(.proYearly))
        #expect(store.entitlement.isActive)
    }

    @Test func lapsedPlansNeverExpireInTheFuture() async throws {
        let (store, client) = try await store()
        let refunded = Date.now.addingTimeInterval(-3_600)
        client.latestByProduct[ShopItem.proYearly.id] = StoreTransaction(
            id: 12, productID: ShopItem.proYearly.id,
            expirationDate: .now.addingTimeInterval(300 * day), revocationDate: refunded)
        await store.refresh()
        #expect(store.entitlement == .expired(refunded))
        client.latestByProduct[ShopItem.proYearly.id] = StoreTransaction(
            id: 13, productID: ShopItem.proYearly.id,
            expirationDate: .now.addingTimeInterval(300 * day))
        await store.refresh()
        #expect(store.entitlement == .none)
        let ended = Date.now.addingTimeInterval(-2 * day)
        client.latestByProduct[ShopItem.proMonthly.id] = StoreTransaction(
            id: 14, productID: ShopItem.proMonthly.id, expirationDate: ended)
        await store.refresh()
        #expect(store.entitlement == .expired(ended))
    }

    @Test func upgradedTransactionsAreIgnored() async throws {
        let (store, client) = try await store()
        let yearly = Date.now.addingTimeInterval(365 * day)
        client.entitlements = [
            StoreTransaction(
                id: 1, productID: ShopItem.proMonthly.id,
                expirationDate: yearly.addingTimeInterval(day), isUpgraded: true),
            StoreTransaction(id: 2, productID: ShopItem.proYearly.id, expirationDate: yearly),
        ]
        await store.refresh()
        #expect(store.entitlement == .active(expires: yearly))
        client.entitlements = [
            StoreTransaction(
                id: 1, productID: ShopItem.proMonthly.id, expirationDate: yearly, isUpgraded: true)
        ]
        await store.refresh()
        #expect(!store.entitlement.isActive)
    }
}
