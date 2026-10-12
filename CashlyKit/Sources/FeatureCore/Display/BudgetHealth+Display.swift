import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension BudgetHealth.Level {
    public var title: String {
        switch self {
        case .critical: String(appLocalized: "Critical")
        case .atRisk: String(appLocalized: "At risk")
        case .overBudget: String(appLocalized: "Over budget")
        case .healthy: String(appLocalized: "Healthy")
        }
    }

    public var summary: String {
        switch self {
        case .critical:
            String(appLocalized: "Spending is far above plan. Act now to get back in control.")
        case .atRisk:
            String(
                appLocalized:
                    "Spending went over budget. Cut non-essential expenses and keep a close eye on your cash so it doesn't get worse."
            )
        case .overBudget:
            String(
                appLocalized:
                    "You went over the planned budget. Adjust spending and focus on the essentials to get back in control."
            )
        case .healthy:
            String(
                appLocalized: "Great! You're within budget and taking good care of your finances.")
        }
    }

    public var color: Color {
        switch self {
        case .critical: .retroRust
        case .atRisk: .retroOrange
        case .overBudget: .retroMustard
        case .healthy: .retroOlive
        }
    }
}
