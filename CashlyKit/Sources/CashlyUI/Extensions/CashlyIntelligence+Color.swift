//
//  CashlyIntelligence+Color.swift
//  CashlyKit
//
//  UI-side color mapping. Keeps CashlyDomain free of SwiftUI (G004/G001).
//

import SwiftUI
import CashlyDomain

public extension CashlyIntelligence {
    var color: Color {
        switch self {
        case .budgetValue:
            return .blue
        case .categoryName:
            return .green
        case .tagValue:
            return .orange
        }
    }
}
