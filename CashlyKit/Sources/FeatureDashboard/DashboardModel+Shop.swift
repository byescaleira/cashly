import CashlyDomain
import Foundation

extension DashboardModel {
    static let spotlightKey = "cashly.home.shopSpotlight.hidden"

    public func shopSpotlight(owned: Set<ShopItem>, on date: Date = .now) -> ShopItem? {
        guard hiddenSpotlightMonth != YearMonth(date).rawValue else { return nil }
        return ShopCatalog.spotlight(on: date, owned: owned, calendar: CashlyCalendar.current)
    }

    public func hideShopSpotlight(on date: Date = .now) {
        hiddenSpotlightMonth = YearMonth(date).rawValue
        defaults.set(hiddenSpotlightMonth, forKey: Self.spotlightKey)
    }
}
