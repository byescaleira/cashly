//
//  FeatureFlagsTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("FeatureFlags", .tags(.unit, .data, .local))
struct FeatureFlagsTests {

    private func suite() -> UserDefaults {
        let name = "cashly.tests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return suite
    }

    @Test("UserDefaults impl returns the seeded default when no override exists")
    func userDefaultsDefault() async {
        let flags = UserDefaultsFeatureFlags(
            suite: suite(),
            defaults: [.experimentalHomeHeader: true]
        )
        #expect(await flags.isEnabled(.experimentalHomeHeader))
        #expect(await flags.isEnabled(.paywallVerticalLayout) == false)
    }

    @Test("UserDefaults override wins over the default")
    func userDefaultsOverride() async {
        let flags = UserDefaultsFeatureFlags(
            suite: suite(),
            defaults: [.experimentalHomeHeader: false]
        )
        await flags.setOverride(.experimentalHomeHeader, enabled: true)
        #expect(await flags.isEnabled(.experimentalHomeHeader))
    }

    @Test("reset drops every override")
    func reset() async {
        let flags = UserDefaultsFeatureFlags(
            suite: suite(),
            defaults: [.experimentalHomeHeader: false]
        )
        await flags.setOverride(.experimentalHomeHeader, enabled: true)
        await flags.reset()
        #expect(await flags.isEnabled(.experimentalHomeHeader) == false)
    }

    @Test("InMemory impl honours initialiser-time overrides")
    func inMemoryOverrideSeed() async {
        let flags = InMemoryFeatureFlags(overrides: [.paywallVerticalLayout: true])
        #expect(await flags.isEnabled(.paywallVerticalLayout))
    }

    @Test("InMemory reset returns to defaults map")
    func inMemoryReset() async {
        let flags = InMemoryFeatureFlags(
            defaults: [.hideIntelligenceForFree: true],
            overrides: [.hideIntelligenceForFree: false]
        )
        #expect(await flags.isEnabled(.hideIntelligenceForFree) == false)
        await flags.reset()
        #expect(await flags.isEnabled(.hideIntelligenceForFree))
    }
}
