import CashlyDomain
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
        case .food: String(appLocalized: "Food")
        case .groceries: String(appLocalized: "Groceries")
        case .transport: String(appLocalized: "Transport")
        case .travel: String(appLocalized: "Travel")
        case .housing: String(appLocalized: "Housing")
        case .bills: String(appLocalized: "Bills and Services")
        case .finance: String(appLocalized: "Finance")
        case .health: String(appLocalized: "Health")
        case .sports: String(appLocalized: "Sports")
        case .shopping: String(appLocalized: "Shopping and Style")
        case .care: String(appLocalized: "Personal Care")
        case .family: String(appLocalized: "Family and Pets")
        case .leisure: String(appLocalized: "Leisure")
        case .education: String(appLocalized: "Education")
        case .work: String(appLocalized: "Work")
        case .technology: String(appLocalized: "Technology")
        case .gifts: String(appLocalized: "Gifts and Parties")
        case .other: String(appLocalized: "Other")
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

    public static func containing(_ symbol: String) -> SymbolCategory? {
        allCases.first { $0.symbols.contains(symbol) }
    }
}
