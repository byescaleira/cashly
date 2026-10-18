import CashlyDomain
import Foundation
import Testing

struct ShopSpotlightTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func date(month: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: 15)))
    }

    @Test func theSeasonalPackLeadsItsMonth() throws {
        let october = try date(month: 10)
        #expect(
            ShopCatalog.spotlight(on: october, owned: [], calendar: calendar) == .iconsHalloween)
        #expect(ShopItem.iconsHalloween.isSeasonal)
    }

    @Test func otherMonthsRotateThroughPacksStillToBuy() throws {
        let march = try #require(
            ShopCatalog.spotlight(on: try date(month: 3), owned: [], calendar: calendar))
        let april = ShopCatalog.spotlight(on: try date(month: 4), owned: [], calendar: calendar)
        #expect(march.kind == .nonConsumable)
        #expect(!march.isSeasonal)
        #expect(march.isAvailable)
        #expect(april != march)
    }

    @Test func ownedPacksAreSkipped() throws {
        let october = try date(month: 10)
        let skipped = ShopCatalog.spotlight(on: october, owned: [.iconsAll], calendar: calendar)
        #expect(skipped?.group != .icons)
        let everything = Set(ShopCatalog.items.filter { $0.kind == .nonConsumable })
        #expect(ShopCatalog.spotlight(on: october, owned: everything, calendar: calendar) == nil)
    }
}
