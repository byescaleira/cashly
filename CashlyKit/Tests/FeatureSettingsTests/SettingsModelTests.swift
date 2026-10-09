import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct SettingsModelTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func appearanceIsSavedForTheNextLaunch() {
        let settings = SettingsModel(defaults: defaults, cloudContainer: nil)
        #expect(settings.appearance == .system)
        settings.appearance = .dark
        #expect(SettingsModel(defaults: defaults, cloudContainer: nil).appearance == .dark)
    }

    @Test func cloudSyncChangeWaitsForTheNextLaunch() {
        let settings = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(settings.isCloudAvailable)
        #expect(settings.syncsAtLaunch)
        #expect(settings.cloudAccount == .checking)
        settings.syncsWithICloud = false
        #expect(settings.needsRestart)
        #expect(settings.cloudFooter == "A mudança vale na próxima vez que o Cashly abrir.")
        settings.syncsWithICloud = true
        #expect(!settings.needsRestart)
        let next = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(next.syncsAtLaunch)
    }

    @Test func turnedOffSyncStartsLocal() {
        defaults.set(false, forKey: "cashly.settings.cloudSync")
        let settings = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(!settings.syncsAtLaunch)
        #expect(settings.cloudFooter == "Seus dados ficam só neste aparelho.")
    }

    @Test func withoutContainerCloudIsUnavailable() async {
        let settings = SettingsModel(defaults: defaults, cloudContainer: nil)
        #expect(!settings.isCloudAvailable)
        #expect(!settings.syncsAtLaunch)
        #expect(!settings.needsRestart)
        #expect(!settings.isSyncOn)
        await settings.loadCloudAccount()
        #expect(settings.cloudAccount == .unavailable)
    }
}
