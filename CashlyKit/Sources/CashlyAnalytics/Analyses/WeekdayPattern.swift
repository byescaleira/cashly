import CashlyDomain
import Foundation

public struct WeekdayPattern: Analysis {
    public static let id: AnalysisID = "weekday-pattern"
    public static let title = "By weekday"
    public static let detail =
        "Average one-off spending on each day of the week over the last 13 weeks."
    public static let version = 1

    private let window = 91

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let covered = ledger.coveredDays(lastDays: window)
        let purchases = ledger.purchases(lastDays: covered)
        guard covered >= 28, purchases.count >= 20 else { return nil }
        let calendar = CashlyCalendar.current
        let totals = Dictionary(grouping: purchases) { calendar.component(.weekday, from: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.minorUnits } }
        let occurrences = Dictionary(
            grouping: (0..<covered).compactMap {
                calendar.date(byAdding: .day, value: -$0, to: ledger.startOfToday)
            }
        ) { calendar.component(.weekday, from: $0) }.mapValues(\.count)
        let weekdays = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        let averages = weekdays.map { weekday -> (Int, Int64) in
            let days = Int64(max(occurrences[weekday] ?? 1, 1))
            return (weekday, (totals[weekday] ?? 0) / days)
        }
        let total = totals.values.reduce(0, +)
        guard total > 0, let top = averages.max(by: { $0.1 < $1.1 }) else { return nil }
        let share = Double(totals[top.0] ?? 0) / Double(total)
        let daily = total / Int64(covered)
        let confidence: Provenance.Confidence = covered >= window ? .high : .medium
        let findings =
            top.1 >= daily * 3 / 2
            ? [
                Finding(
                    analysisID: Self.id, topic: .spending, subject: "weekday-\(top.0)",
                    label: "\(top.0)",
                    summary:
                        "Weekday \(top.0) concentrates \(Int((share * 100).rounded()))% of one-off spending.",
                    impact: (top.1 - daily) * 13 / 3,
                    metrics: [.money("average", "Average on the day", minorUnits: top.1)],
                    confidence: confidence)
            ] : []
        return result(
            ledger,
            summary:
                "Weekday \(top.0) is the biggest day, with \(Formatting.money(top.1)) on average.",
            metrics: [
                Metric(key: "weekday", label: "Biggest day", value: Double(top.0), unit: .count),
                Metric(key: "share", label: "Share", value: share, unit: .ratio),
                .money("average", "Average on the day", minorUnits: top.1),
                .money("daily", "Average per day", minorUnits: daily),
                Metric(key: "days", label: "Days", value: Double(covered), unit: .days),
            ],
            series: averages.map {
                SeriesPoint(label: "\($0.0)", value: Double($0.1) / 100)
            },
            findings: findings,
            method:
                "One-off purchases of the last 13 weeks summed by weekday and divided by how many of that weekday the window has; weekday numbers follow Calendar (1 is Sunday)",
            confidence: confidence)
    }
}
