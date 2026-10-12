import CashlyDomain
import SwiftUI

public struct ShopAccess {
    public var owned: Set<ShopItem>
    private let opener: (ShopItem) -> Void

    public init(owned: Set<ShopItem>, open: @escaping (ShopItem) -> Void) {
        self.owned = owned
        opener = open
    }

    public func owns(_ item: ShopItem) -> Bool {
        ShopCatalog.owns(item, in: owned)
    }

    public func open(_ item: ShopItem) {
        opener(item)
    }
}

extension EnvironmentValues {
    @Entry public var shop = ShopAccess(owned: [], open: { _ in })
}
