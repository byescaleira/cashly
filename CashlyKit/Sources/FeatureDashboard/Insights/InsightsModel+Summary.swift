import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation

extension InsightsModel {
    var narrationContext: String {
        guard let gap = outlook?.gap else { return "There is no plan for this month." }
        return gap > 0
            ? "The month is heading over plan." : "The month is heading to close within plan."
    }

    var shownFindings: [Finding] {
        let shown = Set(
            unusual.map(\.id) + changes.map(\.id) + merchants.map(\.id)
                + (recurrences?.items.map(\.id) ?? []) + budgetIdeas.map(\.id)
                + endings.map(\.id))
        return findings.filter {
            shown.contains($0.id) || ($0.analysisID == SmallPurchases.id && small != nil)
                || ($0.analysisID == MonthPace.id && (outlook?.gap ?? 0) > 0)
        }
    }

    func section(for finding: Finding) -> String {
        switch finding.analysisID {
        case UnusualCategories.id: String(appLocalized: "Out of the Ordinary")
        case SpendingDrivers.id: String(appLocalized: "What Changed")
        case MonthPace.id: String(appLocalized: "Month Forecast")
        case RecurringCharges.id: String(appLocalized: "Recurring Charges")
        case SuggestedBudgets.id: String(appLocalized: "Budgets to Create")
        case SmallPurchases.id: String(appLocalized: "Small Purchases")
        case TopMerchants.id: String(appLocalized: "Repeat Purchases")
        default: String(appLocalized: "Coming Months")
        }
    }
}
