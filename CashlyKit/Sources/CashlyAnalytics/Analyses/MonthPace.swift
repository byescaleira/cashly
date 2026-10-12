import CashlyDomain
import Foundation

public struct MonthPace: Analysis {
    public static let id: AnalysisID = "month-pace"
    public static let title = "Month forecast"
    public static let detail =
        "Where the month should close: what already went out, scheduled bills and what you usually spend until the end of the month."
    public static let version = 3

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let expenses = ledger.postings(in: month).filter(\.isExpense)
        let spent = expenses.filter { $0.date <= ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let scheduled = expenses.filter { $0.date > ledger.today }.reduce(0) { $0 + $1.minorUnits }
        guard spent > 0 || scheduled > 0 else { return nil }
        let history = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        let typicalRest: Int64
        let method: String
        if history.isEmpty {
            typicalRest = Int64(
                (Double(spent) / Double(day) * Double(month.dayCount - day)).rounded())
            method = "Spending to date divided by days elapsed, times the days left"
        } else {
            let left = month.dayCount - day
            let rests = history.map {
                Double(
                    ledger.spent(in: $0, throughDay: $0.dayCount)
                        - ledger.spent(in: $0, throughDay: $0.dayCount - left))
            }
            typicalRest = Int64((Statistics.median(rests) ?? 0).rounded())
            method =
                "Spending to date + median of what went out in the same last days of previous months"
        }
        let remaining = max(scheduled, typicalRest)
        let projected = spent + remaining
        let budgeted = ledger.budgeted(in: month)
        var metrics: [Metric] = [
            .money("spent", "Already spent", minorUnits: spent),
            .money("remaining", "Still to go out", minorUnits: remaining),
            .money("scheduled", "Scheduled bills", minorUnits: scheduled),
            .money("projected", "Month forecast", minorUnits: projected),
            Metric(key: "elapsedDays", label: "Days elapsed", value: Double(day), unit: .days),
        ]
        var summary = "The month should close at \(Formatting.money(projected))."
        if budgeted > 0 {
            metrics.append(.money("budgeted", "Planned", minorUnits: budgeted))
            let difference = projected - budgeted
            summary +=
                difference > 0
                ? " That's \(Formatting.money(difference)) over plan."
                : " \(Formatting.money(-difference)) of the plan is still left."
        }
        let confidence: Provenance.Confidence =
            history.count >= 3 ? .high : history.isEmpty ? (day < 10 ? .low : .medium) : .medium
        return result(
            ledger, summary: summary, metrics: metrics, method: method, confidence: confidence)
    }
}
