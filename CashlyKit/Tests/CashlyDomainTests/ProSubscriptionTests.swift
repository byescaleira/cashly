import CashlyDomain
import Foundation
import Testing

struct ProSubscriptionTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    @Test func subscribedGrantsProUntilItExpires() {
        let renewing = ProSubscription(
            state: .subscribed, plan: .proMonthly, expirationDate: now.addingTimeInterval(day))
        #expect(renewing.grantsPro(at: now))
        let ended = ProSubscription(
            state: .subscribed, plan: .proMonthly, willRenew: false,
            expirationDate: now.addingTimeInterval(-1))
        #expect(!ended.grantsPro(at: now))
        let renewingLate = ProSubscription(
            state: .subscribed, plan: .proMonthly, expirationDate: now.addingTimeInterval(-60))
        #expect(renewingLate.grantsPro(at: now))
        #expect(!renewingLate.grantsPro(at: now.addingTimeInterval(day)))
    }

    @Test func gracePeriodKeepsProAndBillingRetryDoesNot() {
        let grace = ProSubscription(
            state: .inGracePeriod, plan: .proYearly, expirationDate: now.addingTimeInterval(-day),
            gracePeriodEnd: now.addingTimeInterval(5 * day), expirationReason: .billingError)
        #expect(grace.grantsPro(at: now))
        #expect(!grace.grantsPro(at: now.addingTimeInterval(6 * day)))
        #expect(grace.hasPaymentIssue)
        #expect(Entitlement(grace, at: now) == .active(expires: now.addingTimeInterval(5 * day)))
        let retry = ProSubscription(
            state: .inBillingRetry, plan: .proYearly, expirationDate: now.addingTimeInterval(-day))
        #expect(!retry.grantsPro(at: now))
        #expect(retry.hasPaymentIssue)
        #expect(Entitlement(retry, at: now) == .expired(now.addingTimeInterval(-day)))
    }

    @Test func revokedAndExpiredNeverGrantPro() {
        let future = now.addingTimeInterval(100 * day)
        for state in [ProSubscription.State.revoked, .expired] {
            let status = ProSubscription(state: state, plan: .proYearly, expirationDate: future)
            #expect(!status.grantsPro(at: now))
            #expect(Entitlement(status, at: now) == .expired(now))
        }
    }

    @Test func trialMapsToTheTrialEntitlement() {
        let ends = now.addingTimeInterval(3 * day)
        let trial = ProSubscription(
            state: .subscribed, plan: .proYearly, expirationDate: ends, isFreeTrial: true)
        #expect(Entitlement(trial, at: now) == .trial(expires: ends))
    }

    @Test func scheduledPlanIsTheNextRenewal() {
        let downgrade = ProSubscription(
            state: .subscribed, plan: .proYearly, renewalPlan: .proMonthly)
        #expect(downgrade.scheduledPlan == .proMonthly)
        #expect(ProSubscription(state: .subscribed, plan: .proYearly).scheduledPlan == nil)
        let off = ProSubscription(
            state: .subscribed, plan: .proYearly, willRenew: false, renewalPlan: .proMonthly)
        #expect(off.scheduledPlan == nil)
        #expect(off.renewalPlan == .proMonthly)
    }

    @Test func currentPrefersTheStatusThatGrantsPro() {
        let lapsed = ProSubscription(
            state: .expired, plan: .proMonthly, expirationDate: now.addingTimeInterval(day))
        let active = ProSubscription(
            state: .subscribed, plan: .proYearly, expirationDate: now.addingTimeInterval(-60))
        #expect(ProSubscription.current([lapsed, active], at: now) == active)
        #expect(ProSubscription.current([], at: now) == nil)
    }

    @Test func annualSitsAboveMonthly() throws {
        let yearly = try #require(ShopItem.proYearly.planLevel)
        let monthly = try #require(ShopItem.proMonthly.planLevel)
        #expect(yearly < monthly)
        #expect(ShopItem.sounds.planLevel == nil)
    }
}
