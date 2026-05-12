//
//  PaywallState.swift
//  CashlyKit
//
//  Owns the in-memory model behind the paywall sheet: available plans,
//  currently-selected plan, purchase progress and any error to show
//  inline. PaywallMiddleware loads plans and runs the purchase; the
//  view binds purely off this struct.
//

import Foundation
import CashlyDomain

public struct PaywallState: CashlyState {
    /// Where the paywall was opened from. Used purely for analytics
    /// + headline copy — does not change the available plans.
    public var trigger: PaywallTrigger
    public var isLoading: Bool
    public var plans: [SubscriptionPlan]
    public var selectedPlanId: String?
    public var isPurchasing: Bool
    public var didPurchase: Bool
    public var error: CashlyError?

    public init(
        trigger: PaywallTrigger = .upgradeButton,
        isLoading: Bool = true,
        plans: [SubscriptionPlan] = [],
        selectedPlanId: String? = nil,
        isPurchasing: Bool = false,
        didPurchase: Bool = false,
        error: CashlyError? = nil
    ) {
        self.trigger = trigger
        self.isLoading = isLoading
        self.plans = plans
        self.selectedPlanId = selectedPlanId
        self.isPurchasing = isPurchasing
        self.didPurchase = didPurchase
        self.error = error
    }

    public static func opened(from trigger: PaywallTrigger) -> PaywallState {
        PaywallState(trigger: trigger)
    }
}

/// Why the paywall was presented. Used for analytics + headline copy.
public enum PaywallTrigger: String, Sendable, Equatable, Codable {
    /// User hit a Free-tier ceiling (3rd category, 5th budget, etc.).
    case limitReached
    /// User opened the Intelligence tab without Pro.
    case intelligenceTab
    /// User explicitly tapped "Upgrade" from settings / a CTA.
    case upgradeButton
}
