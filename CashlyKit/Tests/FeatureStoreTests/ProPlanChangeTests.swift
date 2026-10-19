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
        let database = try CashlyDatabase.open(inMemory: true)
        let session = SessionModel(provider: database, preference: .disabled)
        let client = FakeStoreClient()
        client.catalog = [
            StoreProduct(
                id: ShopItem.proMonthly.id, displayPrice: "R$ 14,90", price: 14.90,
                period: .month),
            StoreProduct(
                id: ShopItem.proYearly.id, displayPrice: "R$ 99,90", price: 99.90, period: .year),
        ]
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = StoreModel(
            session: session, client: client, defaults: defaults, scheduler: scheduler)
        await store.loadProducts()
        return (store, client)
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
        #expect(store.paymentNotice?.detail.contains("bring Cashly Pro back") == true)
        #expect(!store.canSubscribe)
        #expect(store.planSwitch == nil)
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

    @Test func monthlyOffersTheImmediateUpgrade() async throws {
        let (store, client) = try await store()
        let renews = Date.now.addingTimeInterval(10 * day)
        client.statuses = [
            ProSubscription(state: .subscribed, plan: .proMonthly, expirationDate: renews)
        ]
        await store.refresh()
        let change = try #require(store.planSwitch)
        #expect(change.target == .proYearly)
        #expect(change.title == "Switch to Annual")
        #expect(change.message.contains("R$ 99,90"))
        #expect(change.message.contains("refunds the unused part"))
        let yearly = Date.now.addingTimeInterval(365 * day)
        client.next = .success(
            StoreTransaction(id: 3, productID: ShopItem.proYearly.id, expirationDate: yearly))
        client.statuses = [
            ProSubscription(state: .subscribed, plan: .proYearly, expirationDate: yearly)
        ]
        #expect(await store.switchPlan())
        #expect(store.subscription?.plan == .proYearly)
        #expect(store.planSwitch?.target == .proMonthly)
    }

    @Test func annualOffersTheDowngradeAtRenewal() async throws {
        let (store, client) = try await store()
        let renews = Date.now.addingTimeInterval(100 * day)
        client.statuses = [
            ProSubscription(state: .subscribed, plan: .proYearly, expirationDate: renews)
        ]
        await store.refresh()
        let change = try #require(store.planSwitch)
        #expect(change.target == .proMonthly)
        #expect(change.title == "Switch to Monthly")
        #expect(change.message.contains("R$ 14,90"))
        #expect(change.message.contains(Entitlement.day(renews)))
        client.statuses = [
            ProSubscription(
                state: .subscribed, plan: .proYearly, renewalPlan: .proMonthly,
                expirationDate: renews)
        ]
        await store.refresh()
        #expect(store.planSwitch == nil)
        #expect(store.planDetail == "Switches to Monthly on \(Entitlement.day(renews))")
    }

    @Test func trialHasNoPlanSwitchAndLosesItsReminderWhenRenewalStops() async throws {
        let (store, client) = try await store()
        let ends = Date.now.addingTimeInterval(5 * day)
        client.statuses = [
            ProSubscription(
                state: .subscribed, plan: .proMonthly, expirationDate: ends, isFreeTrial: true)
        ]
        await store.refresh()
        #expect(store.entitlement == .trial(expires: ends))
        #expect(store.planSwitch == nil)
        #expect(await scheduler.scheduled[TrialReminder.id] == nil)
        client.statuses = [
            ProSubscription(
                state: .subscribed, plan: .proMonthly, willRenew: false, expirationDate: ends,
                expirationReason: .cancelled, isFreeTrial: true)
        ]
        await store.refresh()
        #expect(store.planDetail?.contains("renewal off") == true)
        #expect(await scheduler.scheduled[TrialReminder.id] == [])
    }

    @Test func simulatedStatesDescribeThePlan() async throws {
        let (store, _) = try await store()
        store.simulatedPlan = .gracePeriod
        #expect(store.entitlement.isActive)
        #expect(store.paymentNotice != nil)
        store.simulatedPlan = .billingRetry
        #expect(!store.entitlement.isActive)
        #expect(store.planTitle == "On Hold")
        store.simulatedPlan = .renewalOff
        #expect(store.planDetail?.contains("renewal off") == true)
        store.simulatedPlan = .downgrade
        #expect(store.planDetail?.hasPrefix("Switches to Monthly on") == true)
        store.simulatedPlan = .pro
        #expect(store.planSwitch?.target == .proYearly)
        store.simulatedPlan = .real
        #expect(store.subscription == nil)
    }
}
