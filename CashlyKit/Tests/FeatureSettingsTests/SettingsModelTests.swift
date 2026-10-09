import CashlyDomain
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct SettingsModelTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    private let currency = CurrencySetting()

    @Test func currencyIsSavedAndApplied() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(settings.currency == "BRL")
        settings.currency = "USD"
        #expect(currency.code == "USD")
        let other = CurrencySetting()
        let next = SettingsModel(defaults: defaults, cloudContainer: nil, currencySetting: other)
        #expect(next.currency == "USD")
        #expect(other.code == "USD")
        #expect(next.currencyName("BRL") == "Real brasileiro")
    }

    @Test func appearanceIsSavedForTheNextLaunch() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(settings.appearance == .system)
        settings.appearance = .dark
        #expect(
            SettingsModel(defaults: defaults, cloudContainer: nil, currencySetting: currency)
                .appearance == .dark)
    }

    @Test func cloudSyncChangeWaitsForTheNextLaunch() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: "iCloud.test", currencySetting: currency)
        #expect(settings.isCloudAvailable)
        #expect(settings.syncsAtLaunch)
        #expect(settings.cloudAccount == .checking)
        settings.syncsWithICloud = false
        #expect(settings.needsRestart)
        #expect(settings.cloudFooter == "A mudança vale na próxima vez que o Cashly abrir.")
        settings.syncsWithICloud = true
        #expect(!settings.needsRestart)
        let next = SettingsModel(
            defaults: defaults, cloudContainer: "iCloud.test", currencySetting: currency)
        #expect(next.syncsAtLaunch)
    }

    @Test func turnedOffSyncStartsLocal() {
        defaults.set(false, forKey: "cashly.settings.cloudSync")
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: "iCloud.test", currencySetting: currency)
        #expect(!settings.syncsAtLaunch)
        #expect(settings.cloudFooter == "Seus dados ficam só neste aparelho.")
    }

    @Test func withoutContainerCloudIsUnavailable() async {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(!settings.isCloudAvailable)
        #expect(!settings.syncsAtLaunch)
        #expect(!settings.needsRestart)
        #expect(!settings.isSyncOn)
        await settings.loadCloudAccount()
        #expect(settings.cloudAccount == .unavailable)
    }
}
