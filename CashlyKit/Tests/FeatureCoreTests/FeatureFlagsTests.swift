import CashlyDomain
import FeatureCore
import Foundation
import Testing

private struct FixedSource: RemoteFlagSource {
    let flags: [String: RemoteFlag]
    func fetch() async throws -> [String: RemoteFlag] { flags }
}

@MainActor
struct FeatureFlagsTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString) ?? .standard
    }

    @Test func defaultsThenRemoteThenOverride() async {
        let store = defaults()
        let flags = FeatureFlags(
            defaults: store, source: FixedSource(flags: ["mcpServer": RemoteFlag(isOn: false)]))
        #expect(flags.isOn(.mcpServer))
        await flags.refresh()
        #expect(!flags.isOn(.mcpServer))
        flags.override(.mcpServer, true)
        #expect(flags.isOn(.mcpServer))
        flags.override(.mcpServer, nil)
        #expect(!FeatureFlags(defaults: store).isOn(.mcpServer))
    }

    @Test func rolloutUsesAStableBucket() async {
        let store = defaults()
        let flags = FeatureFlags(
            defaults: store,
            source: FixedSource(flags: ["guides": RemoteFlag(isOn: true, rollout: 0)]))
        await flags.refresh()
        #expect(!flags.isOn(.guides))
        #expect(FeatureFlags(defaults: store).bucket == flags.bucket)
        #expect((0..<100).contains(flags.bucket))
    }
}
