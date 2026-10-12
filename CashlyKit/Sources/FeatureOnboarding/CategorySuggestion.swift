import CashlyDomain
import FeatureCore
import Foundation

public enum CategorySuggestion: String, CaseIterable, Identifiable, Sendable {
    case groceries, restaurants, transport, home, bills, health, leisure, education, shopping, pets

    public static let defaults: Set<CategorySuggestion> = [
        .groceries, .restaurants, .transport, .home, .bills, .health,
    ]

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .groceries: String(appLocalized: "Groceries")
        case .restaurants: String(appLocalized: "Restaurants")
        case .transport: String(appLocalized: "Transport")
        case .home: String(appLocalized: "Housing")
        case .bills: String(appLocalized: "Bills")
        case .health: String(appLocalized: "Health")
        case .leisure: String(appLocalized: "Leisure")
        case .education: String(appLocalized: "Education")
        case .shopping: String(appLocalized: "Shopping")
        case .pets: String(appLocalized: "Pets")
        }
    }

    public var icon: String {
        switch self {
        case .groceries: "cart.fill"
        case .restaurants: "fork.knife"
        case .transport: "car.fill"
        case .home: "house.fill"
        case .bills: "bolt.fill"
        case .health: "heart.fill"
        case .leisure: "gamecontroller.fill"
        case .education: "graduationcap.fill"
        case .shopping: "bag.fill"
        case .pets: "pawprint.fill"
        }
    }

    public var color: RetroColor {
        switch self {
        case .groceries: .olive
        case .restaurants: .burntOrange
        case .transport: .denim
        case .home: .terracotta
        case .bills: .mustard
        case .health: .cherry
        case .leisure: .plum
        case .education: .teal
        case .shopping: .dustyRose
        case .pets: .caramel
        }
    }

    func category(for user: User) -> CashlyDomain.Category {
        CashlyDomain.Category(
            id: UUID().uuidString, user: user, name: name, color: color.hex, icon: icon)
    }
}
