import CashlyDomain
import SwiftUI

extension BudgetHealth.Level {
    public var title: String {
        switch self {
        case .critical: "Critical"
        case .atRisk: "At Risk"
        case .overBudget: "Over Budget"
        case .healthy: "Healthy"
        }
    }

    public var summary: String {
        switch self {
        case .critical:
            "You are spending significantly above your planned budget. Immediate action is required to regain control."
        case .atRisk:
            "Your spending is above your budget. Take steps to reduce discretionary expenses and monitor your cash flow closely to avoid further overspending."
        case .overBudget:
            "You have exceeded your planned budget. Adjust your spending immediately and focus on essential costs to regain control of your finances."
        case .healthy:
            "Excellent! You are within your planned budget and managing your finances well."
        }
    }

    public var color: Color {
        switch self {
        case .critical: .red
        case .atRisk: .orange
        case .overBudget: .yellow
        case .healthy: .green
        }
    }
}
