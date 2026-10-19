import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
struct ProPlanSwitchTests {
    private let day: TimeInterval = 86_400
    private let scheduler = FakeScheduler()

    private func store() async throws -> (StoreModel, FakeStoreClient) {
        try await ProStoreFixture.store(scheduler: scheduler)
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
        #expect(change.price == "R$ 99,90/year")
        #expect(change.action == "Switch for R$ 99,90/year")
        #expect(change.planName == "Annual")
        let annual = try #require(store.products[.proYearly])
        #expect(change.fact == "\(annual.formatted(annual.price / 12))/month")
        #expect(!change.fact.contains("99,90"))
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
        #expect(change.price == "R$ 14,90/month")
        #expect(change.action == "Switch on \(Entitlement.day(renews))")
        #expect(change.planName == "Monthly")
        #expect(change.fact == "Starts on \(Entitlement.day(renews))")
        #expect(change.message.contains(Entitlement.day(renews)))
        #expect(store.renewalNotice == nil)
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
        #expect(store.renewalNotice != nil)
        #expect(await scheduler.scheduled[TrialReminder.id] == [])
    }

    @Test func simulatedStatesDescribeThePlan() async throws {
        let (store, _) = try await store()
        store.simulatedPlan = .gracePeriod
        #expect(store.entitlement.isActive)
        #expect(store.paymentNotice != nil)
        store.simulatedPlan = .billingRetry
        #expect(!store.entitlement.isActive)
        #expect(store.isOnHold)
        #expect(store.trialDays == nil)
        #expect(store.planTitle == "On Hold")
        store.simulatedPlan = .renewalOff
        #expect(store.planDetail?.contains("renewal off") == true)
        #expect(store.planSwitch == nil)
        #expect(store.renewalNotice != nil)
        store.simulatedPlan = .downgrade
        #expect(store.planDetail?.hasPrefix("Switches to Monthly on") == true)
        store.simulatedPlan = .pro
        #expect(store.planSwitch?.target == .proYearly)
        store.simulatedPlan = .real
        #expect(store.subscription == nil)
    }
}
