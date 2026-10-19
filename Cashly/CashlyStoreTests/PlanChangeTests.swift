import CashlyDomain
import FeatureStore
import Foundation
import StoreKit
import StoreKitTest
import Testing

extension StoreKitTests {
    @MainActor @Suite struct PlanChange {
        private let day: TimeInterval = 86_400

        private func paid(_ plan: ShopItem) async throws -> StoreKitFixture {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: plan))
            try fixture.session.forceRenewalOfSubscription(productIdentifier: plan.id)
            try await fixture.settle { fixture.store.entitlement.isPaid }
            #expect(fixture.store.subscription?.plan == plan)
            return fixture
        }

        private func isPro() async throws -> Bool {
            let defaults = try #require(UserDefaults(suiteName: "plan-change-\(UUID().uuidString)"))
            return await ProRule.isPro(
                isEnforced: true, client: StoreKitClient(), defaults: defaults)
        }

        private func switchWatching(_ store: StoreModel) async -> (Bool, [Entitlement]) {
            let watcher = Task { @MainActor in
                var seen: [Entitlement] = []
                while !Task.isCancelled {
                    seen.append(store.entitlement)
                    try? await Task.sleep(for: .milliseconds(1))
                }
                return seen
            }
            let switched = await store.switchPlan()
            watcher.cancel()
            return (switched, await watcher.value + [store.entitlement])
        }

        @Test func upgradeStartsAnnualRightAway() async throws {
            let fixture = try await paid(.proMonthly)
            #expect(fixture.store.planSwitch?.target == .proYearly)
            let (switched, seen) = await switchWatching(fixture.store)
            #expect(switched)
            #expect(seen.allSatisfy { $0.isPaid })
            let subscription = try #require(fixture.store.subscription)
            #expect(subscription.plan == .proYearly)
            #expect(subscription.scheduledPlan == nil)
            #expect(!subscription.isFreeTrial)
            let expires = try #require(fixture.store.entitlement.expires)
            #expect(expires > .now.addingTimeInterval(360 * day))
            #expect(try await isPro())
            #expect(fixture.store.planSwitch?.target == .proMonthly)
            let history = await StoreKitClient().history()
            let monthly = try #require(
                history.filter { $0.productID == ShopItem.proMonthly.id }.max { $0.id < $1.id })
            #expect(monthly.isUpgraded)
            #expect(try !fixture.transaction(for: .proMonthly).autoRenewingEnabled)
        }

        @Test func downgradeWaitsForTheRenewal() async throws {
            let fixture = try await paid(.proYearly)
            let renews = try #require(fixture.store.subscription?.expirationDate)
            let count = fixture.session.allTransactions().count
            #expect(fixture.store.planSwitch?.target == .proMonthly)
            #expect(await fixture.store.switchPlan())
            #expect(fixture.session.allTransactions().count == count)
            let scheduled = try #require(fixture.store.subscription)
            #expect(scheduled.plan == .proYearly)
            #expect(scheduled.scheduledPlan == .proMonthly)
            #expect(fixture.store.entitlement == .active(expires: renews))
            #expect(fixture.store.planSwitch == nil)
            #expect(fixture.store.planDetail?.hasPrefix("Switches to Monthly on") == true)
            #expect(try await isPro())
            try fixture.session.forceRenewalOfSubscription(
                productIdentifier: ShopItem.proYearly.id)
            try await fixture.settle { fixture.store.subscription?.plan == .proMonthly }
            let renewed = try #require(fixture.store.subscription)
            #expect(renewed.plan == .proMonthly)
            #expect(renewed.scheduledPlan == nil)
            #expect(!renewed.isFreeTrial)
            #expect(fixture.store.entitlement.isPaid)
            let expires = try #require(fixture.store.entitlement.expires)
            #expect(expires < .now.addingTimeInterval(32 * day))
            #expect(fixture.store.planSwitch?.target == .proYearly)
            #expect(try await isPro())
        }

        @Test func buyingTheCurrentPlanAgainCancelsTheDowngrade() async throws {
            let fixture = try await paid(.proYearly)
            let renews = try #require(fixture.store.subscription?.expirationDate)
            #expect(await fixture.store.switchPlan())
            #expect(fixture.store.subscription?.scheduledPlan == .proMonthly)
            let count = fixture.session.allTransactions().count
            #expect(await fixture.store.buy(.proYearly))
            #expect(fixture.session.allTransactions().count == count)
            #expect(fixture.store.subscription?.scheduledPlan == nil)
            #expect(fixture.store.entitlement == .active(expires: renews))
            #expect(fixture.store.planSwitch?.target == .proMonthly)
            try fixture.session.forceRenewalOfSubscription(
                productIdentifier: ShopItem.proYearly.id)
            try await fixture.settle { fixture.session.allTransactions().count > count }
            try await fixture.settle { fixture.store.subscription?.expirationDate != renews }
            #expect(fixture.store.subscription?.plan == .proYearly)
        }

        @Test func upgradingDuringTheTrialEndsItAndStartsPaying() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            #expect(fixture.store.entitlement.isTrial)
            #expect(fixture.store.planSwitch == nil)
            #expect(await fixture.store.buy(.proYearly))
            let subscription = try #require(fixture.store.subscription)
            #expect(subscription.plan == .proYearly)
            #expect(!subscription.isFreeTrial)
            #expect(fixture.store.entitlement.isPaid)
            let expires = try #require(fixture.store.entitlement.expires)
            #expect(expires > .now.addingTimeInterval(360 * day))
            await fixture.store.loadProducts()
            #expect(fixture.store.introEligible.isEmpty)
        }

        @Test func downgradingDuringTheTrialKeepsItAndSwitchesWhenItEnds() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proYearly))
            let ends = try #require(fixture.store.entitlement.expires)
            let count = fixture.session.allTransactions().count
            #expect(await fixture.store.buy(.proMonthly))
            #expect(fixture.session.allTransactions().count == count)
            let subscription = try #require(fixture.store.subscription)
            #expect(subscription.plan == .proYearly)
            #expect(subscription.isFreeTrial)
            #expect(subscription.scheduledPlan == .proMonthly)
            #expect(fixture.store.entitlement == .trial(expires: ends))
            #expect(fixture.store.planSwitch == nil)
            #expect(await fixture.store.buy(.proYearly))
            #expect(fixture.store.subscription?.scheduledPlan == nil)
            #expect(fixture.store.entitlement == .trial(expires: ends))
        }

        @Test(arguments: ShopCatalog.plans)
        func switchingNeverGivesTheTrialBack(from plan: ShopItem) async throws {
            let fixture = try await paid(plan)
            #expect(await fixture.store.switchPlan())
            if plan == .proYearly {
                try fixture.session.forceRenewalOfSubscription(productIdentifier: plan.id)
                try await fixture.settle { fixture.store.subscription?.plan == .proMonthly }
            }
            let subscription = try #require(fixture.store.subscription)
            #expect(subscription.plan != plan)
            #expect(!subscription.isFreeTrial)
            #expect(fixture.store.entitlement.isPaid)
            await fixture.store.loadProducts()
            #expect(fixture.store.introEligible.isEmpty)
        }

        @Test(arguments: ShopCatalog.plans)
        func tenureKeepsCountingAcrossTheSwitch(from plan: ShopItem) async throws {
            let fixture = try await StoreKitFixture()
            try await fixture.session.buyProduct(
                identifier: plan.id, options: [.purchaseDate(.now.addingTimeInterval(-100 * day))])
            await fixture.store.refresh()
            #expect(fixture.store.subscription?.plan == plan)
            #expect(fixture.store.proMonths == 3)
            #expect(await fixture.store.switchPlan())
            if plan == .proYearly {
                try fixture.session.forceRenewalOfSubscription(productIdentifier: plan.id)
                try await fixture.settle { fixture.store.subscription?.plan == .proMonthly }
            }
            #expect(fixture.store.subscription?.plan != plan)
            #expect(fixture.store.entitlement.isPaid)
            #expect(fixture.store.proMonths == 3)
        }
    }
}
