import Foundation

public enum SymbolCategory: Int, Hashable, CaseIterable, Identifiable, Sendable {
    case food
    case groceries
    case transport
    case travel
    case housing
    case bills
    case finance
    case health
    case sports
    case shopping
    case care
    case family
    case leisure
    case education
    case work
    case technology
    case gifts
    case other

    public var id: Int { rawValue }

    public var name: String {
        switch self {
        case .food: "Alimentação"
        case .groceries: "Mercado"
        case .transport: "Transporte"
        case .travel: "Viagem"
        case .housing: "Casa"
        case .bills: "Contas e serviços"
        case .finance: "Finanças"
        case .health: "Saúde"
        case .sports: "Esportes"
        case .shopping: "Compras e estilo"
        case .care: "Cuidados pessoais"
        case .family: "Família e pets"
        case .leisure: "Lazer"
        case .education: "Educação"
        case .work: "Trabalho"
        case .technology: "Tecnologia"
        case .gifts: "Presentes e festas"
        case .other: "Outros"
        }
    }

    public var systemImage: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .transport: "car.fill"
        case .travel: "airplane"
        case .housing: "house.fill"
        case .bills: "bolt.fill"
        case .finance: "banknote.fill"
        case .health: "heart.fill"
        case .sports: "figure.run"
        case .shopping: "bag.fill"
        case .care: "comb.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .leisure: "gamecontroller.fill"
        case .education: "graduationcap.fill"
        case .work: "briefcase.fill"
        case .technology: "laptopcomputer"
        case .gifts: "gift.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    public var symbols: [String] {
        switch self {
        case .food: Self.foodSymbols
        case .groceries: Self.groceriesSymbols
        case .transport: Self.transportSymbols
        case .travel: Self.travelSymbols
        case .housing: Self.housingSymbols
        case .bills: Self.billsSymbols
        case .finance: Self.financeSymbols
        case .health: Self.healthSymbols
        case .sports: Self.sportsSymbols
        case .shopping: Self.shoppingSymbols
        case .care: Self.careSymbols
        case .family: Self.familySymbols
        case .leisure: Self.leisureSymbols
        case .education: Self.educationSymbols
        case .work: Self.workSymbols
        case .technology: Self.technologySymbols
        case .gifts: Self.giftsSymbols
        case .other: Self.otherSymbols
        }
    }

    public static var random: SymbolCategory {
        allCases.randomElement() ?? .other
    }

    public static func containing(_ symbol: String) -> SymbolCategory? {
        allCases.first { $0.symbols.contains(symbol) }
    }
}
