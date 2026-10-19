import CashlyDomain
import FeatureStore
import Foundation
import StoreKit
import StoreKitTest
import Testing

extension StoreKitTests {
    @MainActor @Suite struct Subscription {
        @Test(arguments: ShopCatalog.plans)
        func subscribingStartsTheFreeTrial(plan: ShopItem) async throws {
            let fixture = try await StoreKitFixture()
            #expect(fixture.store.introEligible == Set(ShopCatalog.plans))
            #expect(await fixture.subscribe(to: plan))
            #expect(fixture.store.entitlement.isTrial)
            let expires = try #require(fixture.store.entitlement.expires)
            #expect(expires > .now.addingTimeInterval(6 * 86_400))
            #expect(fixture.store.error == nil)
        }

        @Test func theTrialIsSpentForTheWholeGroup() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            await fixture.store.loadProducts()
            #expect(fixture.store.introEligible.isEmpty)
        }

        @Test func forcedRenewalTurnsTheTrialIntoAPaidPlan() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            try fixture.session.forceRenewalOfSubscription(
                productIdentifier: ShopItem.proMonthly.id)
            try await fixture.settle { fixture.store.entitlement.isPaid }
            #expect(fixture.store.entitlement.isPaid)
        }

        @Test func expiringLapsesThePlan() async throws {
            let fixture = try await StoreKitFixture()
            fixture.session.timeRate = .oneRenewalEveryTwoSeconds
            #expect(await fixture.subscribe(to: .proYearly))
            let transaction = try fixture.transaction(for: .proYearly)
            try fixture.session.disableAutoRenewForTransaction(identifier: transaction.identifier)
            try await fixture.settle { fixture.store.entitlement.isExpired }
            #expect(fixture.store.entitlement.isExpired)
            #expect(!fixture.store.entitlement.isActive)
        }

        @Test func turningOffRenewalKeepsProUntilTheEnd() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            let transaction = try fixture.transaction(for: .proMonthly)
            try fixture.session.disableAutoRenewForTransaction(identifier: transaction.identifier)
            await fixture.store.refresh()
            #expect(fixture.store.entitlement.isTrial)
        }

        @Test func refundRevokesPro() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            let transaction = try fixture.transaction(for: .proMonthly)
            try fixture.session.refundTransaction(identifier: transaction.identifier)
            try await fixture.settle { !fixture.store.entitlement.isActive }
            #expect(!fixture.store.entitlement.isActive)
        }

        @Test func askToBuyWaitsForTheParentAndThenUnlocks() async throws {
            let fixture = try await StoreKitFixture()
            fixture.session.askToBuyEnabled = true
            #expect(await !fixture.subscribe(to: .proYearly))
            #expect(fixture.store.isPending)
            #expect(!fixture.store.entitlement.isActive)
            let transaction = try fixture.transaction(for: .proYearly)
            #expect(transaction.pendingAskToBuyConfirmation)
            try fixture.session.approveAskToBuyTransaction(identifier: transaction.identifier)
            try await fixture.settle { fixture.store.entitlement.isActive }
            #expect(fixture.store.entitlement.isActive)
        }

        @Test func askToBuyDeclinedKeepsTheFreePlan() async throws {
            let fixture = try await StoreKitFixture()
            fixture.session.askToBuyEnabled = true
            #expect(await !fixture.subscribe(to: .proMonthly))
            let transaction = try fixture.transaction(for: .proMonthly)
            try fixture.session.declineAskToBuyTransaction(identifier: transaction.identifier)
            await fixture.store.refresh()
            #expect(!fixture.store.entitlement.isActive)
        }

        @Test func failedPurchaseSurfacesTheError() async throws {
            let fixture = try await StoreKitFixture()
            try await fixture.session.setSimulatedError(
                .generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
            #expect(await !fixture.subscribe(to: .proMonthly))
            #expect(fixture.store.error != nil)
            #expect(fixture.store.entitlement == .none)
            try await fixture.session.setSimulatedError(nil, forAPI: .purchase)
        }

        @Test func billingRetryWithoutGraceDropsProUntilResolved() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            fixture.session.shouldEnterBillingRetryOnRenewal = true
            try fixture.session.forceRenewalOfSubscription(
                productIdentifier: ShopItem.proMonthly.id)
            try await fixture.settle(.inBillingRetryPeriod)
            #expect(try await fixture.renewalState() == .inBillingRetryPeriod)
            withKnownIssue(
                "StoreKit Testing keeps a subscription in billing retry in currentEntitlements",
                isIntermittent: true
            ) {
                #expect(!fixture.store.entitlement.isActive)
            }
            let transaction = try fixture.transaction(for: .proMonthly)
            try fixture.session.resolveIssueForTransaction(identifier: transaction.identifier)
            try await fixture.settle(.subscribed)
            #expect(try await fixture.renewalState() == .subscribed)
            #expect(fixture.store.entitlement.isPaid)
        }

        @Test func gracePeriodKeepsProWhileTheChargeIsRetried() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proMonthly))
            fixture.session.shouldEnterBillingRetryOnRenewal = true
            fixture.session.billingGracePeriodIsEnabled = true
            try fixture.session.forceRenewalOfSubscription(
                productIdentifier: ShopItem.proMonthly.id)
            try await fixture.settle(.inGracePeriod)
            #expect(try await fixture.renewalState() == .inGracePeriod)
            #expect(fixture.store.entitlement.isActive)
        }

        @Test func restoringBringsTheSubscriptionBack() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.subscribe(to: .proYearly))
            let other = try await StoreKitFixture.model(on: fixture.database)
            #expect(await other.restoreSubscription())
            #expect(other.entitlement.isTrial)
        }
    }
}
