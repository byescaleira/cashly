import CashlyDomain
import Foundation

public struct UnusualCategories: Analysis {
    public static let id: AnalysisID = "unusual-categories"
    public static let title = "Fora do padrão"
    public static let detail =
        "Categorias com gasto bem acima do normal para este ponto do mês."
    public static let version = 2

    private let minimumGap: Int64 = 5_000

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let previous = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        guard previous.count >= 3 else { return nil }
        let points = ledger.categories.compactMap { category -> SeriesPoint? in
            let current = ledger.spent(in: month, throughDay: day, categoryID: category.id)
            let history = previous.map {
                Double(ledger.spent(in: $0, throughDay: day, categoryID: category.id))
            }
            guard let median = Statistics.median(history), Double(current) >= median * 1.5,
                Double(current) - median >= Double(minimumGap)
            else { return nil }
            if let score = Statistics.robustZScore(Double(current), in: history), score < 2 {
                return nil
            }
            if median == 0,
                previous.contains(where: {
                    ledger.spent(in: $0, throughDay: $0.dayCount, categoryID: category.id) > 0
                })
            {
                return nil
            }
            return SeriesPoint(
                label: category.name, value: Double(current) / 100, reference: median / 100)
        }
        .sorted { $0.value - ($0.reference ?? 0) > $1.value - ($1.reference ?? 0) }
        guard let first = points.first else { return nil }
        let summary =
            points.count == 1
            ? "\(first.label) está acima do normal para este ponto do mês."
            : "\(points.count) categorias estão acima do normal para este ponto do mês."
        return result(
            ledger, summary: summary,
            metrics: [
                Metric(
                    key: "count", label: "Categorias", value: Double(points.count), unit: .count)
            ],
            series: Array(points.prefix(3)),
            method: "Gasto até hoje comparado à mediana dos últimos meses, com z-score robusto",
            confidence: previous.count >= 5 ? .high : .medium)
    }
}
