import CashlyDomain
import Foundation

public struct SuggestedBudgets: Analysis {
    public static let id: AnalysisID = "suggested-budgets"
    public static let title = "Budgets to create"
    public static let detail =
        "Categories with spending in most recent months and no budget this month, with what usually goes out in a month."
    public static let version = 1

    private let minimum: Int64 = 5_000

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let previous = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        guard previous.count >= 3 else { return nil }
        let budgeted = Set(ledger.budgets.filter { $0.month == month }.map(\.category.id))
        let monthly = BudgetRule.monthlyTotals(ledger, before: month)
        let findings = ledger.categories.compactMap { category -> Finding? in
            guard !budgeted.contains(category.id) else { return nil }
            let totals = monthly[category.id] ?? []
            guard totals.count * 2 > previous.count, let suggested = BudgetRule.suggested(totals),
                suggested >= minimum
            else { return nil }
            return Finding(
                analysisID: Self.id, topic: .saving, subject: category.id, label: category.name,
                summary:
                    "\(category.name) has no budget this month; about \(Formatting.money(suggested)) usually goes out.",
                impact: suggested,
                metrics: [
                    .money("suggested", "Suggested budget", minorUnits: suggested),
                    Metric(
                        key: "months", label: "Months", value: Double(totals.count), unit: .count),
                ],
                recommendation: Recommendation(action: .setBudget, monthlySaving: 0),
                confidence: totals.count >= 5 ? .high : .medium)
        }
        .sorted { $0.impact == $1.impact ? $0.id < $1.id : $0.impact > $1.impact }
        guard !findings.isEmpty else { return nil }
        return result(
            ledger,
            summary: "\(findings.count) categories usually have spending but no budget this month.",
            metrics: [
                Metric(
                    key: "count", label: "Categories", value: Double(findings.count), unit: .count)
            ],
            findings: findings,
            method:
                "Categories without a budget this month that had spending in more than half of the recent months with activity; the suggestion is the median of those months rounded up to the next 10, from 50 up",
            confidence: .medium)
    }
}
