import CashlyDomain
import SwiftUI

public struct ShopAccess {
    public var owned: Set<ShopItem>
    public var isPro: Bool
    private let pricer: (ShopItem) -> String?
    private let opener: (ShopItem) -> Void
    private let proPresenter: () -> Void

    public init(
        owned: Set<ShopItem>, isPro: Bool = false,
        price: @escaping (ShopItem) -> String? = { _ in nil },
        open: @escaping (ShopItem) -> Void, presentPro: @escaping () -> Void = {}
    ) {
        self.owned = owned
        self.isPro = isPro
        pricer = price
        opener = open
        proPresenter = presentPro
    }

    public func owns(_ item: ShopItem) -> Bool {
        ShopCatalog.owns(item, in: owned)
    }

    public func access(to item: ShopItem?, proOnly: Bool = false) -> PackAccess {
        if proOnly { return isPro ? .included : .pro }
        guard let item else { return .included }
        return owns(item) ? .owned : .locked(item)
    }

    public func unlock(_ access: PackAccess) {
        if access == .pro {
            proPresenter()
        } else if let item = access.lockedItem {
            opener(item)
        }
    }

    public func price(for item: ShopItem) -> String? {
        pricer(item)
    }

    public func open(_ item: ShopItem) {
        opener(item)
    }
}

extension EnvironmentValues {
    @Entry public var shop = ShopAccess(owned: [], open: { _ in })
}
