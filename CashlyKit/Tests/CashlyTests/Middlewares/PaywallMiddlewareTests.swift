//
//  PaywallMiddlewareTests.swift
//  CashlyKit
//
//  Exercises the analytics + state contract of the paywall flow.
//  Uses InMemorySubscriptionService for the dependency and
//  RecordingAnalyticsTracker for assertions.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation
import PrismArchitecture

@Suite("PaywallMiddleware", .tags(.unit, .presentation, .local))
struct PaywallMiddlewareTests {

    private func makeMiddleware(
        subscription: InMemorySubscriptionService = InMemorySubscriptionService(),
        analytics: RecordingAnalyticsTracker = RecordingAnalyticsTracker()
    ) -> (PaywallMiddleware, InMemorySubscriptionService, RecordingAnalyticsTracker) {
        let mw = PaywallMiddleware(subscription: subscription, analytics: analytics)
        return (mw, subscription, analytics)
    }

    @Test("fetch loads plans and emits paywall_viewed")
    func fetchEmitsViewed() async {
        let (mw, _, analytics) = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: .opened(from: .upgradeButton),
            action: .fetch
        ))
        guard case let .update(plans) = actions.first else {
            Issue.record("expected .update — got \(String(describing: actions))"); return
        }
        #expect(plans.isEmpty == false)
        #expect(analytics.events.contains { $0.event == "paywall_viewed" })
    }

    @Test("purchase happy path emits started + succeeded")
    func purchaseSucceededEmits() async {
        let (mw, _, analytics) = makeMiddleware()
        var state = PaywallState.opened(from: .limitReached)
        state.selectedPlanId = "com.cashly.pro.monthly"
        let actions = await collectActions(from: mw.run(state: state, action: .purchase))
        if case .purchaseSucceeded = actions.first {} else {
            Issue.record("expected .purchaseSucceeded — got \(String(describing: actions))")
        }
        let names = analytics.events.map(\.event)
        #expect(names.contains("paywall_purchase_started"))
        #expect(names.contains("paywall_purchase_succeeded"))
        let started = analytics.events.first { $0.event == "paywall_purchase_started" }
        #expect(started?.properties["plan_id"] == "com.cashly.pro.monthly")
        #expect(started?.properties["trigger"] == "limitReached")
    }

    @Test("purchase cancelled emits started + cancelled")
    func purchaseCancelled() async {
        let subscription = InMemorySubscriptionService(nextPurchaseOutcome: .userCancelled)
        let (mw, _, analytics) = makeMiddleware(subscription: subscription)
        var state = PaywallState.opened(from: .upgradeButton)
        state.selectedPlanId = "com.cashly.pro.monthly"
        let actions = await collectActions(from: mw.run(state: state, action: .purchase))
        if case .purchaseCancelled = actions.first {} else {
            Issue.record("expected .purchaseCancelled — got \(String(describing: actions))")
        }
        let names = analytics.events.map(\.event)
        #expect(names.contains("paywall_purchase_cancelled"))
    }

    @Test("purchase failed emits classified reason")
    func purchaseFailedClassified() async {
        let subscription = InMemorySubscriptionService(
            nextPurchaseOutcome: .failed(reason: "The network connection was lost.")
        )
        let (mw, _, analytics) = makeMiddleware(subscription: subscription)
        var state = PaywallState.opened(from: .upgradeButton)
        state.selectedPlanId = "com.cashly.pro.monthly"
        _ = await collectActions(from: mw.run(state: state, action: .purchase))
        let failed = analytics.events.first { $0.event == "paywall_purchase_failed" }
        #expect(failed?.properties["reason_kind"] == "network")
    }

    @Test("purchase failed buckets user cancel reason")
    func purchaseFailedUserCancelled() async {
        let subscription = InMemorySubscriptionService(
            nextPurchaseOutcome: .failed(reason: "User cancelled.")
        )
        let (mw, _, analytics) = makeMiddleware(subscription: subscription)
        var state = PaywallState.opened(from: .upgradeButton)
        state.selectedPlanId = "com.cashly.pro.monthly"
        _ = await collectActions(from: mw.run(state: state, action: .purchase))
        let failed = analytics.events.first { $0.event == "paywall_purchase_failed" }
        #expect(failed?.properties["reason_kind"] == "user_cancelled")
    }

    @Test("purchase without selectedPlanId emits invalidInput, no started event")
    func purchaseWithoutSelection() async {
        let (mw, _, analytics) = makeMiddleware()
        let state = PaywallState.opened(from: .upgradeButton)
        let actions = await collectActions(from: mw.run(state: state, action: .purchase))
        if case .error(.domain(.invalidInput)) = actions.first {} else {
            Issue.record("expected .error(.domain(.invalidInput)) — got \(String(describing: actions.first))")
        }
        // Guard fires before reaching the subscription call, so no
        // analytics events ever leave the middleware.
        #expect(analytics.events.contains { $0.event == "paywall_purchase_started" } == false)
    }

    @Test("purchase failed with unknown reason falls into 'unknown' bucket")
    func purchaseFailedUnknownBucket() async {
        let subscription = InMemorySubscriptionService(
            nextPurchaseOutcome: .failed(reason: "Some unexpected glitch.")
        )
        let (mw, _, analytics) = makeMiddleware(subscription: subscription)
        var state = PaywallState.opened(from: .upgradeButton)
        state.selectedPlanId = "com.cashly.pro.monthly"
        _ = await collectActions(from: mw.run(state: state, action: .purchase))
        let failed = analytics.events.first { $0.event == "paywall_purchase_failed" }
        #expect(failed?.properties["reason_kind"] == "unknown")
    }

    @Test("restore on Pro tier emits started + succeeded")
    func restoreOnProEmitsSucceeded() async {
        let subscription = InMemorySubscriptionService()
        await subscription.setTier(.pro)
        let (mw, _, analytics) = makeMiddleware(subscription: subscription)
        let actions = await collectActions(from: mw.run(
            state: .opened(from: .upgradeButton),
            action: .restore
        ))
        if case .purchaseSucceeded = actions.first {} else {
            Issue.record("expected .purchaseSucceeded — got \(String(describing: actions))")
        }
        let names = analytics.events.map(\.event)
        #expect(names.contains("paywall_restore_started"))
        #expect(names.contains("paywall_restore_succeeded"))
    }

    @Test("restore on Free tier emits no_entitlement")
    func restoreOnFreeEmitsNoEntitlement() async {
        let (mw, _, analytics) = makeMiddleware()
        _ = await collectActions(from: mw.run(
            state: .opened(from: .upgradeButton),
            action: .restore
        ))
        let names = analytics.events.map(\.event)
        #expect(names.contains("paywall_restore_no_entitlement"))
    }

    @Test("passive actions emit nothing")
    func passiveActionsAreNoops() async {
        let (mw, _, _) = makeMiddleware()
        let passive: [PaywallAction] = [
            .update(plans: []),
            .select(planId: "x"),
            .purchaseSucceeded,
            .purchaseCancelled,
            .stopLoading,
            .error(.unknown(message: "x")),
            .replace(.opened(from: .upgradeButton))
        ]
        for action in passive {
            let actions = await collectActions(from: mw.run(
                state: .opened(from: .upgradeButton),
                action: action
            ))
            #expect(actions.isEmpty, "expected no emissions for \(action)")
        }
    }
}
