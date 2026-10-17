import CashlyDomain
import Foundation

public struct MonthPace: Analysis {
    public static let id: AnalysisID = "month-pace"
    public static let title = "Month forecast"
    public static let detail =
        "Where the month should close: what already went out, scheduled bills and what you usually spend until the end of the month."
    public static let version = 4

    public struct Projection: Sendable {
        public let spent: Int64
        public let scheduled: Int64
        public let remaining: Int64
        public let method: String
        public let history: Int

        public var projected: Int64 { spent + remaining }
    }

    public init() {}

    public static func projection(_ ledger: LedgerSnapshot) -> Projection? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let expenses = ledger.postings(in: month).filter(\.isExpense)
        let spent = expenses.filter { $0.date <= ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let scheduled = expenses.filter { $0.date > ledger.today }.reduce(0) { $0 + $1.minorUnits }
        guard spent > 0 || scheduled > 0 else { return nil }
        let history = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        guard !history.isEmpty else {
            let rest = Int64((Double(spent) / Double(day) * Double(month.dayCount - day)).rounded())
            return Projection(
                spent: spent, scheduled: scheduled, remaining: max(scheduled, rest),
                method: "Spending to date divided by days elapsed, times the days left",
                history: 0)
        }
        let left = month.dayCount - day
        let rests = history.map {
            Double(
                ledger.spent(in: $0, throughDay: $0.dayCount)
                    - ledger.spent(in: $0, throughDay: $0.dayCount - left))
        }
        let rest = Int64((Statistics.median(rests) ?? 0).rounded())
        return Projection(
            spent: spent, scheduled: scheduled, remaining: max(scheduled, rest),
            method:
                "Spending to date + median of what went out in the same last days of previous months",
            history: history.count)
    }

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        guard let projection = Self.projection(ledger) else { return nil }
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let spent = projection.spent
        let scheduled = projection.scheduled
        let remaining = projection.remaining
        let projected = projection.projected
        let method = projection.method
        let budgeted = ledger.budgeted(in: month)
        var metrics: [Metric] = [
            .money("spent", "Already spent", minorUnits: spent),
            .money("remaining", "Still to go out", minorUnits: remaining),
            .money("scheduled", "Scheduled bills", minorUnits: scheduled),
            .money("projected", "Month forecast", minorUnits: projected),
            Metric(key: "elapsedDays", label: "Days elapsed", value: Double(day), unit: .days),
        ]
        let confidence: Provenance.Confidence =
            projection.history >= 3
            ? .high : projection.history == 0 ? (day < 10 ? .low : .medium) : .medium
        var summary = "The month should close at \(Formatting.money(projected))."
        var findings: [Finding] = []
        if budgeted > 0 {
            metrics.append(.money("budgeted", "Planned", minorUnits: budgeted))
            let difference = projected - budgeted
            summary +=
                difference > 0
                ? " That's \(Formatting.money(difference)) over plan."
                : " \(Formatting.money(-difference)) of the plan is still left."
            if difference > 0 {
                findings.append(
                    Finding(
                        analysisID: Self.id, topic: .month, subject: "over-plan",
                        label: Formatting.month(month),
                        summary:
                            "The month should close \(Formatting.money(difference)) over plan.",
                        impact: difference,
                        metrics: [
                            .money("projected", "Month forecast", minorUnits: projected),
                            .money("budgeted", "Planned", minorUnits: budgeted),
                        ],
                        confidence: confidence))
            }
        }
        return result(
            ledger, summary: summary, metrics: metrics, findings: findings, method: method,
            confidence: confidence)
    }
}
