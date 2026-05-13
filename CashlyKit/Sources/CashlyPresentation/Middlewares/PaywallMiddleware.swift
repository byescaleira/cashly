//
//  PaywallMiddleware.swift
//  CashlyKit
//
//  Talks to SubscriptionUseCase: loads plans on .fetch, runs purchase
//  with verification on .purchase, restores on .restore. The view
//  only sees actions and never imports StoreKit.
//

import CashlyDomain
import CashlyResource
import PrismArchitecture

public struct PaywallMiddleware: PrismMiddleware {
    let subscription: SubscriptionUseCase
    let analytics: AnalyticsTracker

    public init(
        subscription: SubscriptionUseCase,
        analytics: AnalyticsTracker = NoopAnalyticsTracker()
    ) {
        self.subscription = subscription
        self.analytics = analytics
    }

    public func run(state: PaywallState, action: PaywallAction) -> PrismEffect<PaywallAction> {
        switch action {
        case .fetch: return fetch()
        case .purchase: return purchase(state: state)
        case .restore: return restore()
        case .update, .select, .purchaseSucceeded, .purchaseCancelled,
             .restoreFinishedNoEntitlement, .stopLoading, .error, .replace:
            return .none
        }
    }

    private func fetch() -> PrismEffect<PaywallAction> {
        .run { [analytics, subscription] send in
            await subscription.refreshPlans()
            let plans = await subscription.availablePlans()
            analytics.track(event: "paywall_viewed", properties: ["plans": "\(plans.count)"])
            send(.update(plans: plans))
        }
    }

    private func purchase(state: PaywallState) -> PrismEffect<PaywallAction> {
        .run { [analytics, subscription] send in
            guard let planId = state.selectedPlanId else {
                send(.error(.domain(.invalidInput(field: "plan", reason: "Pick a plan to continue."))))
                return
            }
            analytics.track(event: "paywall_purchase_started", properties: [
                "plan_id": planId,
                "trigger": state.trigger.rawValue
            ])
            let outcome = await subscription.purchase(planId: planId)
            switch outcome {
            case .success:
                analytics.track(event: "paywall_purchase_succeeded", properties: [
                    "plan_id": planId,
                    "trigger": state.trigger.rawValue
                ])
                send(.purchaseSucceeded)
            case .userCancelled:
                analytics.track(event: "paywall_purchase_cancelled", properties: [
                    "plan_id": planId
                ])
                send(.purchaseCancelled)
            case .pending:
                // Pending purchases (Ask to Buy, etc.) finish via
                // Transaction.updates — the listener flips global
                // SubscriptionStatus once Apple resolves it.
                analytics.track(event: "paywall_purchase_pending", properties: [
                    "plan_id": planId
                ])
                send(.stopLoading)
            case let .failed(reason):
                // Bucket the raw StoreKit reason into a low-cardinality
                // tag so analytics don't explode with PII / per-txn
                // strings. Full reason still flows into state.error +
                // logs for support triage.
                analytics.track(event: "paywall_purchase_failed", properties: [
                    "plan_id": planId,
                    "reason_kind": Self.classify(failure: reason)
                ])
                send(.error(.unknown(message: reason)))
            }
        }
    }

    /// Map raw StoreKit failure descriptions onto a small enum-style
    /// tag set so analytics cardinality stays bounded.
    private static func classify(failure reason: String) -> String {
        let lowered = reason.lowercased()
        if lowered.contains("cancel") { return "user_cancelled" }
        if lowered.contains("network") || lowered.contains("connection") { return "network" }
        if lowered.contains("payment") || lowered.contains("billing") { return "payment" }
        if lowered.contains("not allowed") || lowered.contains("restricted") { return "restricted" }
        return "unknown"
    }

    private func restore() -> PrismEffect<PaywallAction> {
        .run { [analytics, subscription] send in
            analytics.track(event: "paywall_restore_started")
            await subscription.restore()
            let status = await subscription.currentStatus()
            if status.tier == .pro {
                analytics.track(event: "paywall_restore_succeeded")
                send(.purchaseSucceeded)
            } else {
                analytics.track(event: "paywall_restore_no_entitlement")
                send(.restoreFinishedNoEntitlement)
            }
        }
    }
}
