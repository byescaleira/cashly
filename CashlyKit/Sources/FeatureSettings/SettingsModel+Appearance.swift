import CashlyDomain
import FeatureCore
import Foundation

struct ThemeSample {
    struct Row: Identifiable {
        let symbol: String
        let title: String
        let color: RetroColor
        let amount: String
        let fraction: Double

        var id: String { symbol }
    }

    let title: String
    let caption: String
    let balance: String
    let rows: [Row]
}

extension SettingsModel {
    var tintName: String { RetroColor.name(for: tint) }

    var themeFooter: String {
        switch appearance {
        case .system:
            String(appLocalized: "Cashly follows the light and dark setting of your device.")
        case .light, .dark:
            String(appLocalized: "Cashly keeps this look whatever your device uses.")
        }
    }

    var themeSample: ThemeSample {
        ThemeSample(
            title: String(appLocalized: "Home"),
            caption: String(appLocalized: "Available"),
            balance: Money(minorUnits: 184_250).formatted,
            rows: [
                ThemeSample.Row(
                    symbol: "cart", title: String(appLocalized: "Groceries"), color: .olive,
                    amount: Money(minorUnits: 32_090).formatted, fraction: 0.64),
                ThemeSample.Row(
                    symbol: "house", title: String(appLocalized: "Housing"), color: .denim,
                    amount: Money(minorUnits: 12_000).formatted, fraction: 0.3),
            ])
    }

    var quickIcons: [AppIcon] { AppIcon.Collection.colors.icons }

    var showsCurrentIconApart: Bool { !quickIcons.contains(appIcon) }

    var allIconsPreview: [AppIcon] {
        AppIcon.Collection.allCases.filter { $0.shopItem != nil }.prefix(4).compactMap(
            \.icons.first)
    }

    func access(to item: ShopItem?, in shop: ShopAccess) -> PackAccess {
        shop.access(to: item)
    }

    func access(to collection: AppIcon.Collection, in shop: ShopAccess) -> PackAccess {
        access(to: collection.shopItem, in: shop)
    }

    func choose(_ icon: AppIcon, in shop: ShopAccess) async {
        if let item = access(to: icon.shopItem, in: shop).lockedItem {
            shop.open(item)
        } else {
            await setAppIcon(icon)
        }
    }

    func iconCollections(on date: Date, calendar: Calendar = .current) -> [AppIcon.Collection] {
        let featured = AppIcon.featured(on: date, calendar: calendar)
        let others = AppIcon.Collection.allCases.filter { $0 != featured }
        return (featured.map { [$0] } ?? []) + others
    }

    func isFeatured(_ collection: AppIcon.Collection, on date: Date) -> Bool {
        AppIcon.featured(on: date) == collection
    }

    func offersAllIcons(in shop: ShopAccess) -> Bool {
        !shop.owns(.iconsAll)
            && AppIcon.Collection.allCases.contains { access(to: $0, in: shop).lockedItem != nil }
    }
}
