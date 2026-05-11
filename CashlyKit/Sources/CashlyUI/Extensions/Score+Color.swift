//
//  Score+Color.swift
//  CashlyKit
//
//  Maps domain ScoreLevel to SwiftUI Color at the UI boundary so
//  CashlyDomain stays SwiftUI-free.
//

import SwiftUI
import CashlyDomain

public extension Score {
    var color: Color {
        switch level {
        case .critical: return .red
        case .atRisk: return .orange
        case .overBudget: return .yellow
        case .healthy: return .green
        }
    }
}
