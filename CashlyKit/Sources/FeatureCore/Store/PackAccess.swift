import CashlyDomain

public enum PackAccess: Equatable, Sendable {
    case included, owned
    case locked(ShopItem)

    public var lockedItem: ShopItem? {
        if case .locked(let item) = self { item } else { nil }
    }

    public func label(price: String?) -> String? {
        switch self {
        case .included: nil
        case .owned: String(appLocalized: "Owned")
        case .locked: price ?? String(appLocalized: "Locked")
        }
    }
}
