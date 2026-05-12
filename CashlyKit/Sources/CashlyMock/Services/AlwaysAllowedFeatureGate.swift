//
//  AlwaysAllowedFeatureGate.swift
//  CashlyKit
//
//  Default-Pro feature gate for tests + previews. Tests that need
//  Free-tier behaviour can use `StubFeatureGate` below to script
//  per-feature decisions.
//

import Foundation
import CashlyDomain

public struct AlwaysAllowedFeatureGate: FeatureGateUseCase {
    public let limits: FeatureGateLimits

    public init(limits: FeatureGateLimits = .freeDefault) {
        self.limits = limits
    }

    public func decide(_ feature: FeatureGate) async -> FeatureGateDecision { .allowed }
}

/// Per-feature decision script. Defaults to `.allowed` for any gate
/// not explicitly configured.
public actor StubFeatureGate: FeatureGateUseCase {
    private var decisions: [FeatureGate: FeatureGateDecision]
    public nonisolated let limits: FeatureGateLimits

    public init(
        decisions: [FeatureGate: FeatureGateDecision] = [:],
        limits: FeatureGateLimits = .freeDefault
    ) {
        self.decisions = decisions
        self.limits = limits
    }

    public func decide(_ feature: FeatureGate) async -> FeatureGateDecision {
        decisions[feature] ?? .allowed
    }

    public func set(_ decision: FeatureGateDecision, for feature: FeatureGate) {
        decisions[feature] = decision
    }
}
