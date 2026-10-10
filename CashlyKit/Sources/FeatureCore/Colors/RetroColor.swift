import CashlyDesignSystem
import SwiftUI

public enum RetroColor: String, CaseIterable, Identifiable, Sendable {
    case cherry, rust, terracotta, dustyRose, salmon
    case burntOrange, tangerine, caramel, mustard, sunflower
    case avocado, olive, moss, sage, mint
    case teal, turquoise, denim, sky, indigo
    case plum, lavender, eggplant
    case coffee, sand, slate

    public static let `default` = RetroColor.burntOrange

    public var id: String { rawValue }

    public var color: Color { Color(hex: hex) }

    public init?(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        guard let match = Self.allCases.first(where: { digits.hasPrefix($0.hex) }) else {
            return nil
        }
        self = match
    }

    public var hex: String {
        switch self {
        case .cherry: "B23A48"
        case .rust: "B5482F"
        case .terracotta: "C8693F"
        case .dustyRose: "C47C86"
        case .salmon: "DB8B6E"
        case .burntOrange: "C2602A"
        case .tangerine: "E08A2E"
        case .caramel: "B67D3E"
        case .mustard: "C9962B"
        case .sunflower: "DDB040"
        case .avocado: "8A9A3A"
        case .olive: "6B7D35"
        case .moss: "5C7A4E"
        case .sage: "8EA389"
        case .mint: "5FA894"
        case .teal: "2E7D74"
        case .turquoise: "3A9AA0"
        case .denim: "466A93"
        case .sky: "6F9BC4"
        case .indigo: "5A5F9E"
        case .plum: "85506F"
        case .lavender: "9C88B8"
        case .eggplant: "6D4A72"
        case .coffee: "8A6246"
        case .sand: "BFA27A"
        case .slate: "6E6A66"
        }
    }

    public var name: String {
        switch self {
        case .cherry: "Cereja"
        case .rust: "Ferrugem"
        case .terracotta: "Terracota"
        case .dustyRose: "Rosa antigo"
        case .salmon: "Salmão"
        case .burntOrange: "Laranja queimado"
        case .tangerine: "Tangerina"
        case .caramel: "Caramelo"
        case .mustard: "Mostarda"
        case .sunflower: "Girassol"
        case .avocado: "Abacate"
        case .olive: "Oliva"
        case .moss: "Musgo"
        case .sage: "Sálvia"
        case .mint: "Menta"
        case .teal: "Petróleo"
        case .turquoise: "Turquesa"
        case .denim: "Jeans"
        case .sky: "Céu"
        case .indigo: "Anil"
        case .plum: "Ameixa"
        case .lavender: "Lavanda"
        case .eggplant: "Berinjela"
        case .coffee: "Café"
        case .sand: "Areia"
        case .slate: "Grafite"
        }
    }

    public static func name(for hex: String) -> String {
        RetroColor(hex: hex)?.name ?? "Personalizada"
    }
}
