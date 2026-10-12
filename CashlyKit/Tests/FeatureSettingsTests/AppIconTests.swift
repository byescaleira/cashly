import Foundation
import Testing

@testable import FeatureSettings

@MainActor
private final class FakeIcon: AppIconSwitching {
    var supportsAlternateIcons = true
    var current: String?
    var fails = false

    init(current: String? = nil) {
        self.current = current
    }

    func set(_ name: String?) async throws {
        if fails { throw CocoaError(.featureUnsupported) }
        current = name
    }
}

@MainActor
struct AppIconTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func readsCurrentIconAndSwitches() async {
        let icon = FakeIcon(current: "CashlyIconDark")
        let settings = SettingsModel(defaults: defaults, cloudContainer: nil, iconSwitcher: icon)
        #expect(settings.appIcon == .dark)
        await settings.setAppIcon(.standard)
        #expect(icon.current == nil)
        #expect(settings.appIcon == .standard)
        await settings.setAppIcon(.orange)
        #expect(icon.current == "CashlyIconOrange")
    }

    @Test func failureKeepsTheOldIcon() async {
        let icon = FakeIcon()
        icon.fails = true
        let settings = SettingsModel(defaults: defaults, cloudContainer: nil, iconSwitcher: icon)
        await settings.setAppIcon(.graphite)
        #expect(settings.appIcon == .standard)
        #expect(settings.isShowingIconError)
    }

    @Test func everyAlternateHasAnAsset() {
        #expect(AppIcon.allCases.compactMap(\.assetName).count == AppIcon.allCases.count - 1)
        #expect(AppIcon(assetName: "desconhecido") == .standard)
    }

    @Test func octoberFeaturesHalloween() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        let october = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 10)))
        let march = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        #expect(AppIcon.featured(on: october, calendar: calendar) == .halloween)
        #expect(AppIcon.featured(on: march, calendar: calendar) == nil)
        #expect(AppIcon.Collection.halloween.icons == [.blood, .bat, .skull, .frankenstein])
        let june = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)) ?? .now
        let december = calendar.date(from: DateComponents(year: 2026, month: 12, day: 15)) ?? .now
        #expect(AppIcon.featured(on: june, calendar: calendar) == .junina)
        #expect(AppIcon.featured(on: december, calendar: calendar) == .christmas)
        #expect(AppIcon.Collection.fashion.icons == [.jeans, .tailoring, .leather, .polkaDot])
    }

    @Test func everyCollectionHasFourIcons() {
        for collection in AppIcon.Collection.allCases {
            #expect(collection.icons.count == 4)
        }
        #expect(AppIcon.allCases.count == AppIcon.Collection.allCases.count * 4)
        #expect(Set(AppIcon.allCases.compactMap(\.assetName)).count == AppIcon.allCases.count - 1)
        #expect(AppIcon.candyCane.assetName == "CashlyIconCandyCane")
    }

    @Test func summerAndCarnivalAreFeatured() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        let january = try #require(
            calendar.date(from: DateComponents(year: 2027, month: 1, day: 10)))
        let february = try #require(
            calendar.date(from: DateComponents(year: 2027, month: 2, day: 10)))
        #expect(AppIcon.featured(on: january, calendar: calendar) == .summer)
        #expect(AppIcon.featured(on: february, calendar: calendar) == .carnival)
        #expect(AppIcon.Collection.carnival.icons == [.confetti, .streamer, .frevo, .sequin])
    }
}
