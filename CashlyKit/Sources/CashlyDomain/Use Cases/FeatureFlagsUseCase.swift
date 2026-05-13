//
//  FeatureFlagsUseCase.swift
//  CashlyKit
//
//  Lightweight remote / local feature-flag contract. Today the
//  implementation is UserDefaults-backed for dogfooding + A/B
//  experiments via QA toggles; future ones can plug in GrowthBook /
//  ConfigCat / your-own without touching call sites.
//

import Foundation

public enum FeatureFlag: String, Sendable, CaseIterable, Codable {
    /// Show the new dark-glass header on HomeScreen. Default off.
    case experimentalHomeHeader
    /// Hide the AI Intelligence tab entirely for Free users — soft
    /// kill switch in case a model misbehaves in production.
    case hideIntelligenceForFree
    /// Test variant of the paywall (vertical vs horizontal price
    /// cards). Default off — old layout stays the control.
    case paywallVerticalLayout
}

public protocol FeatureFlagsUseCase: Sendable {
    /// True if the flag is currently enabled. Default per flag
    /// lives at the implementation layer.
    func isEnabled(_ flag: FeatureFlag) async -> Bool

    /// Override the flag locally — useful for QA / debug builds.
    func setOverride(_ flag: FeatureFlag, enabled: Bool) async

    /// Drop every override + revert to the defaults.
    func reset() async
}
