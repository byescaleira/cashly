//
//  CashlySymbolCategory.swift
//  CashlyKit
//
//  Wave 7 G019: enum + name + random helpers only. Symbol catalog data
//  lives in CashlySymbolCategory+Symbols.swift.
//

import Foundation

public enum CashlySymbolCategory: Int, Hashable, CaseIterable {
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
        case .food: return "Food & Shopping"
        case .transport: return "Transport & Travel"
        case .housing: return "Housing & Home"
        case .utilities: return "Bills & Utilities"
        case .health: return "Health & Wellness"
        case .entertainment: return "Entertainment & Leisure"
        case .education: return "Education & Work"
        case .technology: return "Technology & Communication"
        }
    }

    public static var random: CashlySymbolCategory {
        allCases.randomElement() ?? .technology
    }

    public static var randomSymbol: String {
        CashlySymbolCategory.random.symbols.randomElement() ?? "questionmark"
    }
}
