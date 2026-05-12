//
//  SubscriptionUseCase.swift
//  CashlyKit
//
//  Subscription / entitlement contract. Production-side impl in
//  CashlyData talks to StoreKit 2; in-memory impl in CashlyMock
//  toggles tiers for tests and previews. UI and feature-gating logic
//  consume this protocol, never StoreKit directly.
//

import Foundation

public enum SubscriptionTier: String, Sendable, CaseIterable, Codable {
    /// Free tier — capped limits across users, categories, budgets.
    case free
    /// Paid tier — unlimited entities + AI features.
    case pro
}

/// One purchasable Cashly subscription plan.
public struct SubscriptionPlan: Sendable, Equatable, Identifiable {
    public let id: String
    /// User-facing display name (e.g. "Pro Monthly").
    public let displayName: String
    /// Localized price string already formatted by StoreKit
    /// (e.g. "$4.99"). Empty when offline / before product load.
    public let displayPrice: String
    /// "monthly" | "yearly" | "weekly" | "lifetime", etc.
    public let period: String?

    public init(id: String, displayName: String, displayPrice: String, period: String?) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.period = period
    }
}

/// Snapshot of the user's subscription state.
public struct SubscriptionStatus: Sendable, Equatable {
    public let tier: SubscriptionTier
    public let activePlanId: String?
    public let expiresAt: Date?
    public let willAutoRenew: Bool

    public init(
        tier: SubscriptionTier,
        activePlanId: String? = nil,
        expiresAt: Date? = nil,
        willAutoRenew: Bool = false
    ) {
        self.tier = tier
        self.activePlanId = activePlanId
        self.expiresAt = expiresAt
        self.willAutoRenew = willAutoRenew
    }

    public static let free = SubscriptionStatus(tier: .free)
}

/// Outcome of a single purchase attempt — keep the surface narrow so
/// UI doesn't have to know about StoreKit's verification states.
public enum PurchaseOutcome: Sendable, Equatable {
    case success
    case userCancelled
    case pending
    case failed(reason: String)
}

public protocol SubscriptionUseCase: Sendable {
    /// Currently known plans (Pro monthly + yearly today). Empty until
    /// the first successful product load.
    func availablePlans() async -> [SubscriptionPlan]

    /// Force a product catalog refresh from the store.
    func refreshPlans() async

    /// Current entitlement snapshot — `.free` by default until a paid
    /// transaction is observed.
    func currentStatus() async -> SubscriptionStatus

    /// Attempt to purchase the plan with the given id.
    func purchase(planId: String) async -> PurchaseOutcome

    /// Restore previously purchased entitlements (Settings restore).
    func restore() async

    /// AsyncStream of status changes. UI watches this to react to
    /// renew / expire / refund events from `Transaction.updates`.
    func statusUpdates() -> AsyncStream<SubscriptionStatus>
}
