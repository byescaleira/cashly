//
//  PaywallAction.swift
//  CashlyKit
//

import CashlyDomain

public enum PaywallAction: CashlyReplaceableAction {
    public typealias State = PaywallState

    case fetch
    case update(plans: [SubscriptionPlan])
    case select(planId: String)
    case purchase
    case purchaseSucceeded
    case purchaseCancelled
    case restore
    /// Emitted when `restore` completes but no Pro entitlement is
    /// found — UI can show a "Nothing to restore" toast/banner.
    case restoreFinishedNoEntitlement
    case stopLoading
    case error(CashlyError)
    case replace(PaywallState)
}
