//
//  PaywallMiddleware.swift
//  CashlyKit
//
//  Talks to SubscriptionUseCase: loads plans on .fetch, runs purchase
//  with verification on .purchase, restores on .restore. The view
//  only sees actions and never imports StoreKit.
//

import CashlyDomain
import PrismArchitecture

public struct PaywallMiddleware: PrismMiddleware {
    let subscription: SubscriptionUseCase

    public init(subscription: SubscriptionUseCase) {
        self.subscription = subscription
    }

    public func run(state: PaywallState, action: PaywallAction) -> PrismEffect<PaywallAction> {
        switch action {
        case .fetch: return fetch()
        case .purchase: return purchase(state: state)
        case .restore: return restore()
        case .update, .select, .purchaseSucceeded, .purchaseCancelled,
             .stopLoading, .error, .replace:
            return .none
        }
    }

    private func fetch() -> PrismEffect<PaywallAction> {
        .run { send in
            await subscription.refreshPlans()
            let plans = await subscription.availablePlans()
            send(.update(plans: plans))
        }
    }

    private func purchase(state: PaywallState) -> PrismEffect<PaywallAction> {
        .run { send in
            guard let planId = state.selectedPlanId else {
                send(.error(.domain(.invalidInput(field: "plan", reason: "Pick a plan to continue."))))
                return
            }
            let outcome = await subscription.purchase(planId: planId)
            switch outcome {
            case .success:
                send(.purchaseSucceeded)
            case .userCancelled:
                send(.purchaseCancelled)
            case .pending:
                // Pending purchases (Ask to Buy, etc.) finish via
                // Transaction.updates — the listener flips global
                // SubscriptionStatus once Apple resolves it.
                send(.stopLoading)
            case let .failed(reason):
                send(.error(.unknown(message: reason)))
            }
        }
    }

    private func restore() -> PrismEffect<PaywallAction> {
        .run { send in
            await subscription.restore()
            let status = await subscription.currentStatus()
            if status.tier == .pro {
                send(.purchaseSucceeded)
            } else {
                send(.stopLoading)
            }
        }
    }
}
