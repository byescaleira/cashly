import CashlyDomain
import Foundation

public struct SmallPurchases: Analysis {
    public static let id: AnalysisID = "small-purchases"
    public static let title = "Small purchases"
    public static let detail =
        "Purchases up to your usual amount this month, how much they add up to and what that means in a year."
    public static let version = 2

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let history = ledger.purchases(lastDays: 180)
        guard history.count >= 20,
            let median = Statistics.median(history.map { Double($0.minorUnits) })
        else { return nil }
        let threshold = Self.niceFloor(Int64(median))
        guard threshold > 0 else { return nil }
        let month = ledger.currentMonth
        let end = ledger.endOfToday
        let monthPurchases = ledger.postings(in: month).filter { $0.isExpense && $0.date < end }
        let small = monthPurchases.filter { $0.installments <= 1 && $0.minorUnits <= threshold }
        guard small.count >= 3 else { return nil }
        let total = small.reduce(0) { $0 + $1.minorUnits }
        let spent = monthPurchases.reduce(0) { $0 + $1.minorUnits }
        let past = (1...3).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:)).map {
            Double(
                ledger.postings(in: $0).filter {
                    $0.isExpense && $0.installments <= 1 && $0.minorUnits <= threshold
                }
                .reduce(0) { $0 + $1.minorUnits })
        }
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let projected = Double(total) * Double(month.dayCount) / Double(max(day, 1))
        let monthly = Int64((Statistics.mean(past) ?? projected).rounded())
        let share = spent > 0 ? Double(total) / Double(spent) : 0
        let confidence: Provenance.Confidence = past.count >= 3 ? .high : .medium
        return result(
            ledger,
            summary:
                "\(small.count) purchases up to \(Formatting.money(threshold)) add up to \(Formatting.money(total)) this month.",
            metrics: [
                .money("threshold", "Up to", minorUnits: threshold),
                .money("total", "This month", minorUnits: total),
                Metric(key: "count", label: "Purchases", value: Double(small.count), unit: .count),
                Metric(key: "share", label: "Share of the month", value: share, unit: .ratio),
                .money("monthly", "Usual month", minorUnits: monthly),
                .money("yearly", "In a year", minorUnits: monthly * 12),
            ],
            findings: [
                Finding(
                    analysisID: Self.id, topic: .spending, subject: "small",
                    label: Formatting.money(threshold),
                    summary:
                        "Small purchases add up to about \(Formatting.money(monthly * 12)) a year.",
                    impact: monthly, confidence: confidence)
            ],
            method:
                "Purchases up to the median of one-off purchases in the last 180 days, rounded down; the year is the average of the last three months times 12, or this month projected to its end when there are no previous months",
            confidence: confidence)
    }

    public static func niceFloor(_ value: Int64) -> Int64 {
        guard value > 0 else { return 0 }
        var scale: Int64 = 1
        while scale * 10 <= value { scale *= 10 }
        return [5, 3, 2, 1].map { $0 * scale }.first { $0 <= value } ?? scale
    }
}
