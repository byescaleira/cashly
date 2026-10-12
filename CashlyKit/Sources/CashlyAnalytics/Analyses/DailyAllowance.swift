import CashlyDomain
import Foundation

public struct DailyAllowance: Analysis {
    public static let id: AnalysisID = "daily-allowance"
    public static let title = "How much can I spend per day"
    public static let detail =
        "What's left of the plan, minus bills still to come, divided by the remaining days."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let budgeted = ledger.budgeted(in: month)
        guard budgeted > 0 else { return nil }
        let expenses = ledger.postings(in: month).filter(\.isExpense)
        let spent = expenses.filter { $0.date <= ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let upcoming = expenses.filter { $0.date > ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let daysLeft = month.dayCount - day + 1
        let free = budgeted - spent - upcoming
        let daily = free > 0 ? free / Int64(daysLeft) : 0
        let summary =
            free > 0
            ? "You can spend \(Formatting.money(daily)) per day over the next \(daysLeft) days."
            : "The month's plan is already used up, counting bills still to come."
        return result(
            ledger, summary: summary,
            metrics: [
                .money("daily", "Per day", minorUnits: daily),
                .money("free", "Free this month", minorUnits: free),
                .money("upcoming", "Upcoming bills", minorUnits: upcoming),
                Metric(
                    key: "daysLeft", label: "Days left", value: Double(daysLeft), unit: .days),
            ],
            method: "(Planned − spent − upcoming bills this month) ÷ days left",
            confidence: .certain)
    }
}
