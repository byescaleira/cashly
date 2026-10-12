import CashlyDomain
import Foundation

public struct InstallmentCommitments: Analysis {
    public static let id: AnalysisID = "installment-commitments"
    public static let title = "Committed installments"
    public static let detail =
        "How much of the installments and future bills is already committed, month by month."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let start = ledger.currentMonth.adding(months: 1)
        let future = ledger.postings.filter { $0.isExpense && $0.month >= start }
        guard !future.isEmpty else { return nil }
        let series = MonthlySeries.expenses(future)
        let last = future.map(\.month).max() ?? start
        let months = series.months(from: start, to: min(last, start.adding(months: 11)))
        let total = future.reduce(0) { $0 + $1.minorUnits }
        let next = series[start]
        return result(
            ledger,
            summary:
                "You already have \(Formatting.money(total)) committed through \(Formatting.month(last)); \(Formatting.money(next)) is due next month.",
            metrics: [
                .money("total", "Total committed", minorUnits: total),
                .money("nextMonth", "Next month", minorUnits: next),
                Metric(
                    key: "months", label: "Months with installments", value: Double(months.count),
                    unit: .count),
            ],
            series: months.map {
                SeriesPoint(label: Formatting.shortMonth($0), value: Double(series[$0]) / 100)
            },
            method: "Sum of installments and future entries already recorded", confidence: .certain,
            evidence: Array(Set(future.map(\.transactionID))).sorted())
    }
}
