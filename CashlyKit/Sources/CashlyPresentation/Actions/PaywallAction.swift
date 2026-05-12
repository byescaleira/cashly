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
    case stopLoading
    case error(CashlyError)
    case replace(PaywallState)
}
