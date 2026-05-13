//
//  UserDefaultsFeatureFlags.swift
//  CashlyKit
//
//  UserDefaults-backed `FeatureFlagsUseCase`. Flags ship with
//  per-flag defaults; overrides live under
//  `cashly.featureFlags.<rawValue>` so a QA build can flip them
//  without redeploy.
//

import Foundation
import CashlyDomain

public actor UserDefaultsFeatureFlags: FeatureFlagsUseCase {
    private let suite: UserDefaults
    private let defaults: [FeatureFlag: Bool]

    public init(
        suite: UserDefaults = .standard,
        defaults: [FeatureFlag: Bool] = UserDefaultsFeatureFlags.defaultMap
    ) {
        self.suite = suite
        self.defaults = defaults
    }

    /// Ship-time defaults. Tweak when a flag graduates from
    /// experiment to baseline behaviour.
    public static var defaultMap: [FeatureFlag: Bool] {
        [
            .experimentalHomeHeader: false,
            .hideIntelligenceForFree: false,
            .paywallVerticalLayout: false
        ]
    }

    public func isEnabled(_ flag: FeatureFlag) async -> Bool {
        let key = Self.key(for: flag)
        if suite.object(forKey: key) != nil {
            return suite.bool(forKey: key)
        }
        return defaults[flag] ?? false
    }

    public func setOverride(_ flag: FeatureFlag, enabled: Bool) async {
        suite.set(enabled, forKey: Self.key(for: flag))
    }

    public func reset() async {
        for flag in FeatureFlag.allCases {
            suite.removeObject(forKey: Self.key(for: flag))
        }
    }

    private static func key(for flag: FeatureFlag) -> String {
        "cashly.featureFlags.\(flag.rawValue)"
    }
}
