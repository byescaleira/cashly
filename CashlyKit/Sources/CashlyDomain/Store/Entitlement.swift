import Foundation

public enum Entitlement: Equatable, Sendable {
    case none
    case trial(expires: Date)
    case active(expires: Date)
    case expired(Date)

    public var isActive: Bool {
        switch self {
        case .trial, .active: true
        case .none, .expired: false
        }
    }

    public var canWrite: Bool { isActive }

    public var expires: Date? {
        switch self {
        case .trial(let date), .active(let date), .expired(let date): date
        case .none: nil
        }
    }
}

@MainActor
public protocol EntitlementProviding: AnyObject {
    var entitlement: Entitlement { get }
}

public enum PurchaseResult: Equatable, Sendable {
    case purchased, pending, cancelled
}

@MainActor
public protocol PurchaseProviding: AnyObject {
    var owned: Set<ShopItem> { get }
    func purchase(_ item: ShopItem) async throws -> PurchaseResult
    func restore() async throws
}
