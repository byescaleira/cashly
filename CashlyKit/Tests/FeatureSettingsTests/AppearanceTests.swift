import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
private final class IconSpy: AppIconSwitching {
    var supportsAlternateIcons = true
    var current: String?

    func set(_ name: String?) async throws {
        current = name
    }
}

@MainActor
private final class ShopSpy {
    var opened: [ShopItem] = []
    var proPresented = 0

    func access(owning owned: Set<ShopItem> = [], isPro: Bool = false) -> ShopAccess {
        ShopAccess(
            owned: owned, isPro: isPro, open: { self.opened.append($0) },
            presentPro: { self.proPresented += 1 })
    }
}

@MainActor
struct AppearanceTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    private let icons = IconSpy()
    private let shop = ShopSpy()

    private func makeSettings() -> SettingsModel {
        SettingsModel(defaults: defaults, cloudContainer: nil, iconSwitcher: icons)
    }

    @Test func packAccessFollowsOwnership() {
        let settings = makeSettings()
        let none = shop.access()
        #expect(settings.access(to: nil, in: none) == .included)
        #expect(settings.access(to: .accentNeon, in: none) == .locked(.accentNeon))
        #expect(settings.access(to: .accentNeon, in: shop.access(owning: [.accentNeon])) == .owned)
        #expect(settings.access(to: .colors, in: none) == .included)
        #expect(
            settings.access(to: .halloween, in: shop.access(owning: [.iconsAll])) == .owned)
    }

    @Test func tintNameFollowsClassicAndPremiumColors() {
        let settings = makeSettings()
        #expect(settings.tintName == RetroColor.burntOrange.name)
        settings.tint = PremiumColor.gold.hex
        #expect(settings.tintName == PremiumColor.gold.name)
        settings.tint = "123456"
        #expect(settings.tintName == "Custom")
    }

    @Test func lockedIconOpensTheShopAndKeepsTheIcon() async {
        let settings = makeSettings()
        await settings.choose(.skull, in: shop.access())
        #expect(settings.appIcon == .standard)
        #expect(shop.opened == [.iconsHalloween])
        await settings.choose(.dark, in: shop.access())
        #expect(settings.appIcon == .dark)
        #expect(!settings.showsCurrentIconApart)
        await settings.choose(.skull, in: shop.access(owning: [.iconsAll]))
        #expect(settings.appIcon == .skull)
        #expect(icons.current == "CashlyIconSkull")
        #expect(settings.showsCurrentIconApart)
        #expect(shop.opened == [.iconsHalloween])
    }

    @Test func featuredCollectionComesFirst() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        let october = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 14)))
        let march = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let settings = makeSettings()
        let inOctober = settings.iconCollections(on: october, calendar: calendar)
        #expect(inOctober.first == .halloween)
        #expect(inOctober.count == AppIcon.Collection.allCases.count)
        #expect(Set(inOctober.map(\.title)).count == inOctober.count)
        #expect(settings.iconCollections(on: march, calendar: calendar).first == .colors)
    }

    @Test func allIconsIsOfferedWhileAPackIsLocked() {
        let settings = makeSettings()
        #expect(settings.offersAllIcons(in: shop.access()))
        #expect(!settings.offersAllIcons(in: shop.access(owning: [.iconsAll])))
        let packs = Set(AppIcon.Collection.allCases.compactMap(\.shopItem))
        #expect(!settings.offersAllIcons(in: shop.access(owning: packs)))
        #expect(settings.allIconsPreview.count == 4)
        #expect(settings.allIconsPreview.allSatisfy { $0.shopItem != nil })
        #expect(settings.quickIcons.allSatisfy { $0.shopItem == nil })
    }

    @Test func themeFooterAndSampleFollowTheChoice() {
        let settings = makeSettings()
        let automatic = settings.themeFooter
        settings.appearance = .dark
        #expect(settings.themeFooter != automatic)
        #expect(settings.themeSample.rows.count == 2)
        #expect(settings.themeSample.rows.allSatisfy { (0...1).contains($0.fraction) })
    }

    @Test func goldIconsNeedProAndLeaveWhenItEnds() async {
        let settings = makeSettings()
        #expect(settings.access(to: .gold, in: shop.access(owning: [.iconsAll])) == .pro)
        await settings.choose(.blackGold, in: shop.access(owning: [.iconsAll]))
        #expect(settings.appIcon == .standard)
        #expect(shop.proPresented == 1)
        #expect(shop.opened.isEmpty)
        await settings.choose(.blackGold, in: shop.access(isPro: true))
        #expect(settings.appIcon == .blackGold)
        #expect(icons.current == "CashlyIconBlackGold")
        await settings.dropProIcon()
        #expect(settings.appIcon == .standard)
        #expect(!settings.offersAllIcons(in: shop.access(owning: [.iconsAll])))
    }
}
