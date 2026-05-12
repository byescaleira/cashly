//
//  FeatureGateUseCase.swift
//  CashlyKit
//
//  Contract for asking "is the user allowed to perform X right now?".
//  Centralises the Free/Pro matrix so middlewares don't duplicate
//  count-and-compare logic and the paywall has a single trigger
//  vocabulary.
//

import Foundation

/// Capabilities the feature-gate can be queried about. The set is
/// deliberately small — every entry maps to either a paywall trigger
/// or a settings toggle, nothing in between.
public enum FeatureGate: String, Sendable, CaseIterable {
    case addUser
    case addCategory
    case addBudget
    case intelligence
    case multiUser
}

/// Result of a single gate query.
public enum FeatureGateDecision: Sendable, Equatable {
    case allowed
    case blocked(feature: FeatureGate, requiredTier: SubscriptionTier)

    public var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }
}

/// Free-tier hard limits. Centralised so price/limit experiments only
/// touch this struct. Pro tier ignores all of these.
public struct FeatureGateLimits: Sendable, Equatable {
    public let maxUsers: Int
    public let maxCategories: Int
    public let maxBudgets: Int

    public init(maxUsers: Int, maxCategories: Int, maxBudgets: Int) {
        self.maxUsers = maxUsers
        self.maxCategories = maxCategories
        self.maxBudgets = maxBudgets
    }

    /// Default Free-tier ceiling. Tune here, not at call sites.
    public static let freeDefault = FeatureGateLimits(
        maxUsers: 1,
        maxCategories: 3,
        maxBudgets: 5
    )
}

public protocol FeatureGateUseCase: Sendable {
    /// Resolve whether `feature` is currently allowed for the active
    /// tier and current entity counts. Implementations may make their
    /// own queries against persistence to compute counts.
    func decide(_ feature: FeatureGate) async -> FeatureGateDecision

    /// The Free-tier limits in force. Surfaces them to UI for "X of Y
    /// used" messaging without having to re-import the constants.
    var limits: FeatureGateLimits { get }
}
