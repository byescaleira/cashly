import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension BudgetHealth.Level {
    public var color: Color {
        switch self {
        case .critical: .retroRust
        case .atRisk: .retroOrange
        case .overBudget: .retroMustard
        case .healthy: .retroOlive
        }
    }
}
