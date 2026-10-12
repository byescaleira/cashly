import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public enum PremiumColor: String, CaseIterable, Identifiable, Sendable {
    case gold, silver, bronze, copper
    case neonPink, neonCyan, neonLime, neonOrange

    public var id: String { rawValue }

    public var item: ShopItem {
        switch self {
        case .gold, .silver, .bronze, .copper: .accentMetallic
        case .neonPink, .neonCyan, .neonLime, .neonOrange: .accentNeon
        }
    }

    public static func colors(of item: ShopItem) -> [PremiumColor] {
        allCases.filter { $0.item == item }
    }

    public init?(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        guard let match = Self.allCases.first(where: { digits.hasPrefix($0.hex) }) else {
            return nil
        }
        self = match
    }

    public var color: Color { Color(hex: hex) }

    public var hex: String {
        switch self {
        case .gold: "B8912A"
        case .silver: "8A8F99"
        case .bronze: "A6713B"
        case .copper: "B5602F"
        case .neonPink: "F0268A"
        case .neonCyan: "0AA9C7"
        case .neonLime: "5FBF1F"
        case .neonOrange: "F2641A"
        }
    }

    public var name: String {
        switch self {
        case .gold: String(appLocalized: "Gold")
        case .silver: String(appLocalized: "Silver")
        case .bronze: String(appLocalized: "Bronze")
        case .copper: String(appLocalized: "Copper")
        case .neonPink: String(appLocalized: "Neon Pink")
        case .neonCyan: String(appLocalized: "Neon Cyan")
        case .neonLime: String(appLocalized: "Neon Lime")
        case .neonOrange: String(appLocalized: "Neon Orange")
        }
    }
}
