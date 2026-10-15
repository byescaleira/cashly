import CashlyDomain

public enum PackAccess: Equatable, Sendable {
    case included, owned, pro
    case locked(ShopItem)

    public var lockedItem: ShopItem? {
        if case .locked(let item) = self { item } else { nil }
    }

    public var isLocked: Bool { self == .pro || lockedItem != nil }

    public func label(price: String?) -> String? {
        switch self {
        case .included: nil
        case .owned: String(appLocalized: "Owned")
        case .pro: "Pro"
        case .locked: price ?? String(appLocalized: "Locked")
        }
    }

    public var lockValue: String? {
        switch self {
        case .pro: String(appLocalized: "Requires Cashly Pro")
        case .locked: String(appLocalized: "Locked")
        case .included, .owned: nil
        }
    }
}
