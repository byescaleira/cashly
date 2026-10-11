import CashlyDomain
import Foundation

public struct InstallmentCommitments: Analysis {
    public static let id: AnalysisID = "installment-commitments"
    public static let title = "Parcelas já assumidas"
    public static let detail =
        "Quanto das parcelas e contas futuras já está comprometido, mês a mês."
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
                "Você já tem \(Formatting.money(total)) comprometidos até \(Formatting.month(last)); \(Formatting.money(next)) caem no próximo mês.",
            metrics: [
                .money("total", "Total comprometido", minorUnits: total),
                .money("nextMonth", "Próximo mês", minorUnits: next),
                Metric(
                    key: "months", label: "Meses com parcelas", value: Double(months.count),
                    unit: .count),
            ],
            series: months.map {
                SeriesPoint(label: Formatting.shortMonth($0), value: Double(series[$0]) / 100)
            },
            method: "Soma das parcelas e lançamentos futuros já registrados", confidence: .certain,
            evidence: Array(Set(future.map(\.transactionID))).sorted())
    }
}
