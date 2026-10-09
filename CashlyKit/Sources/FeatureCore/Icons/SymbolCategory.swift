import Foundation

public enum SymbolCategory: Int, Hashable, CaseIterable {
    case food
    case transport
    case housing
    case utilities
    case health
    case entertainment
    case education
    case technology

    public var name: String {
        switch self {
        case .food: "Comida e compras"
        case .transport: "Transporte e viagem"
        case .housing: "Casa e moradia"
        case .utilities: "Contas e serviços"
        case .health: "Saúde e bem-estar"
        case .entertainment: "Lazer e entretenimento"
        case .education: "Educação e trabalho"
        case .technology: "Tecnologia e comunicação"
        }
    }

    public var symbols: [String] {
        switch self {
        case .food: Self.foodSymbols
        case .transport: Self.transportSymbols
        case .housing: Self.housingSymbols
        case .utilities: Self.utilitiesSymbols
        case .health: Self.healthSymbols
        case .entertainment: Self.entertainmentSymbols
        case .education: Self.educationSymbols
        case .technology: Self.technologySymbols
        }
    }

    public static var random: SymbolCategory {
        allCases.randomElement() ?? .technology
    }

    public static func containing(_ symbol: String) -> SymbolCategory? {
        allCases.first { $0.symbols.contains(symbol) }
    }
}
