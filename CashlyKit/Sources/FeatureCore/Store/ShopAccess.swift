import CashlyDomain
import SwiftUI

public struct ShopAccess {
    public var owned: Set<ShopItem>
    private let pricer: (ShopItem) -> String?
    private let opener: (ShopItem) -> Void

    public init(
        owned: Set<ShopItem>, price: @escaping (ShopItem) -> String? = { _ in nil },
        open: @escaping (ShopItem) -> Void
    ) {
        self.owned = owned
        pricer = price
        opener = open
    }

    public func owns(_ item: ShopItem) -> Bool {
        ShopCatalog.owns(item, in: owned)
    }

    public func access(to item: ShopItem?) -> PackAccess {
        guard let item else { return .included }
        return owns(item) ? .owned : .locked(item)
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
