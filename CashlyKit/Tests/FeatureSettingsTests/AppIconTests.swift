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
}
