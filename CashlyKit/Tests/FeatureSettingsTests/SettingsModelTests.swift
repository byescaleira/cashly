import CashlyDomain
import FeatureCore
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
        #expect(next.currencyName("BRL").lowercased().contains("real"))
    }

    @Test func privacyPreferencesAreSaved() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(!settings.locksApp)
        #expect(!settings.isDiscreet)
        settings.locksApp = true
        settings.isDiscreet = true
        let next = SettingsModel(defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(next.locksApp)
        #expect(next.isDiscreet)
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

    @Test func tintStartsBurntOrangeAndIsSaved() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: currency)
        #expect(RetroColor(hex: settings.tint) == .burntOrange)
        settings.tint = RetroColor.teal.hex
        #expect(
            SettingsModel(defaults: defaults, cloudContainer: nil, currencySetting: currency)
                .tint == RetroColor.teal.hex)
    }

    @Test func cloudSyncChangeWaitsForTheNextLaunch() {
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: "iCloud.test", currencySetting: currency)
        #expect(settings.isCloudAvailable)
        #expect(settings.syncsAtLaunch)
        #expect(settings.cloudAccount == .checking)
        settings.syncsWithICloud = false
        #expect(settings.needsRestart)
        #expect(settings.cloudFooter == "The change applies the next time Cashly opens.")
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
        #expect(settings.cloudFooter == "Your data stays on this device only.")
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

@MainActor
struct LastSyncTests {
    @Test func keepsTheNewestSyncDate() {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let settings = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(settings.lastSyncText == "Not yet")
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        settings.recordSync(date)
        settings.recordSync(date.addingTimeInterval(-60))
        #expect(settings.lastSync == date)
        #expect(SettingsModel(defaults: defaults, cloudContainer: "iCloud.test").lastSync == date)
    }
}
