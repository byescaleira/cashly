//
//  CashlyIntelligence+Color.swift
//  CashlyKit
//
//  UI-side color mapping. Lives in CashlyUI so CashlyDomain stays
//  SwiftUI-free.
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
