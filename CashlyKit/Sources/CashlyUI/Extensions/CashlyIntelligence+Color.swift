import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension CashlyIntelligence {
    public var color: Color {
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
