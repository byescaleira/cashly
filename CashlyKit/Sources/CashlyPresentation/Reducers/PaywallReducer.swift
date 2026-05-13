//
//  PaywallReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct PaywallReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout PaywallState, action: PaywallAction) -> PrismEffect<PaywallAction> {
        switch action {
        case .fetch:
            state.isLoading = true
            state.error = nil
        case let .update(plans):
            state.plans = plans
            state.isLoading = false
            // Default selection: prefer the yearly plan (better value)
            // when present, otherwise the first plan returned.
            if state.selectedPlanId == nil {
                state.selectedPlanId = plans.first(where: { $0.period == "yearly" })?.id
                    ?? plans.first?.id
            }
        case let .select(planId):
            state.selectedPlanId = planId
        case .purchase:
            state.isPurchasing = true
            state.error = nil
        case .purchaseSucceeded:
            state.isPurchasing = false
            state.didPurchase = true
        case .purchaseCancelled:
            state.isPurchasing = false
        case .restore:
            state.isLoading = true
            state.restoreFinishedNoEntitlement = false
        case .restoreFinishedNoEntitlement:
            state.isLoading = false
            state.restoreFinishedNoEntitlement = true
        case .stopLoading:
            state.isLoading = false
            state.isPurchasing = false
        case let .error(error):
            state.error = error
            state.isLoading = false
            state.isPurchasing = false
        case let .replace(newState):
            state = newState
        }
        return .none
    }
}
