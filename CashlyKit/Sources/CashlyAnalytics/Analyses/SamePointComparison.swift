import CashlyDomain
import Foundation

public struct SamePointComparison: Analysis {
    public static let id: AnalysisID = "same-point"
    public static let title = "Comparado aos meses anteriores"
    public static let detail =
        "Quanto você gastou até hoje, comparado ao mesmo ponto dos três meses anteriores."
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
            ? "Até o dia \(day), você gastou \(Formatting.money(-difference)) a menos que a média dos últimos \(history.count) meses."
            : "Até o dia \(day), você gastou \(Formatting.money(difference)) a mais que a média dos últimos \(history.count) meses."
        return result(
            ledger, summary: summary,
            metrics: [
                .money("spent", "Gasto até hoje", minorUnits: spent),
                .money("average", "Média no mesmo ponto", minorUnits: average),
                .money("difference", "Diferença", minorUnits: difference),
                Metric(
                    key: "ratio", label: "Variação",
                    value: average > 0 ? Double(spent) / Double(average) - 1 : 0, unit: .ratio),
                Metric(key: "day", label: "Dia do mês", value: Double(day), unit: .days),
            ],
            series: zip(previous, history).map {
                SeriesPoint(label: Formatting.shortMonth($0), value: Double($1) / 100)
            } + [SeriesPoint(label: Formatting.shortMonth(month), value: Double(spent) / 100)],
            method: "Gasto até o mesmo dia do mês, comparado à média dos meses anteriores",
            confidence: history.count >= 3 ? .high : .medium)
    }
}
