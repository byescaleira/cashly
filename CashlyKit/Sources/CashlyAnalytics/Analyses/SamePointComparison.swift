import CashlyDomain
import Foundation

public struct SamePointComparison: Analysis {
    public static let id: AnalysisID = "same-point"
    public static let title = "Compared with previous months"
    public static let detail =
        "How much you spent to date, compared with the same point in the previous three months."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let previous = (1...3).map { month.adding(months: -$0) }.reversed()
            .filter(ledger.hasActivity(in:))
        guard !previous.isEmpty else { return nil }
        let history = previous.map { ledger.spent(in: $0, throughDay: day) }
        let spent = ledger.spent(in: month, throughDay: day)
        let average = history.reduce(0, +) / Int64(history.count)
        guard spent > 0 || average > 0 else { return nil }
        let difference = spent - average
        let summary =
            difference <= 0
            ? "Up to day \(day), you spent \(Formatting.money(-difference)) less than the average of the last \(history.count) months."
            : "Up to day \(day), you spent \(Formatting.money(difference)) more than the average of the last \(history.count) months."
        return result(
            ledger, summary: summary,
            metrics: [
                .money("spent", "Spent to date", minorUnits: spent),
                .money("average", "Average at the same point", minorUnits: average),
                .money("difference", "Difference", minorUnits: difference),
                Metric(
                    key: "ratio", label: "Change",
                    value: average > 0 ? Double(spent) / Double(average) - 1 : 0, unit: .ratio),
                Metric(key: "day", label: "Day of month", value: Double(day), unit: .days),
            ],
            series: zip(previous, history).map {
                SeriesPoint(label: Formatting.shortMonth($0), value: Double($1) / 100)
            } + [SeriesPoint(label: Formatting.shortMonth(month), value: Double(spent) / 100)],
            method:
                "Spending up to the same day of the month, compared with the average of previous months",
            confidence: history.count >= 3 ? .high : .medium)
    }
}
