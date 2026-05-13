//
//  InMemoryFeatureFlags.swift
//  CashlyKit
//
//  In-memory FeatureFlagsUseCase for tests + previews. Honours the
//  same per-flag defaults map as the production impl unless an
//  initialiser-time override is supplied.
//

import Foundation
import CashlyDomain

public actor InMemoryFeatureFlags: FeatureFlagsUseCase {
    private var overrides: [FeatureFlag: Bool]
    private let defaults: [FeatureFlag: Bool]

    public init(
        defaults: [FeatureFlag: Bool] = UserDefaultsFeatureFlags.defaultMap,
        overrides: [FeatureFlag: Bool] = [:]
    ) {
        self.defaults = defaults
        self.overrides = overrides
    }

    public func isEnabled(_ flag: FeatureFlag) async -> Bool {
        overrides[flag] ?? defaults[flag] ?? false
    }

    public func setOverride(_ flag: FeatureFlag, enabled: Bool) async {
        overrides[flag] = enabled
    }

    public func reset() async {
        overrides.removeAll()
    }
}
