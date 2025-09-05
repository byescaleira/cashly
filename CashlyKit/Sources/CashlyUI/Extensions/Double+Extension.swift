//
//  Double+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI

extension Double {
    func currencyColor(reference: Double = .zero) -> CashlyColor {
        reference == .zero ?
        (self > reference ? .success : self < reference ? .error : .textSecondary) :
        (self > reference ? .error : self < reference ? .success : .warning)
    }
    
    var percentage: String {
        (self * 100).formatted(.number.precision(.fractionLength(0))) + "%"
    }
    
    var variationMessage: String {
        switch self {
        case ..<0.1: return "Just started"
        case ..<0.5: return "On track"
        case ..<0.9: return "Watch out"
        case ..<1.0: return "Almost spent"
        default: return "Over budget"
        }
    }
    
    var variationColor: Color {
        switch self {
        case ..<0.5: return .green
        case ..<0.9: return .yellow
        case ..<1.0: return .orange
        default: return .red
        }
    }
}
