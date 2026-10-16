import CashlyDomain
import Foundation

public struct UnusualCategories: Analysis {
    public static let id: AnalysisID = "unusual-categories"
    public static let title = "Out of the ordinary"
    public static let detail =
        "Categories with spending well above usual for this point of the month."
    public static let version = 3

    private let minimumGap: Int64 = 5_000

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let previous = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        guard previous.count >= 3 else { return nil }
        let unusual = ledger.categories.compactMap {
            category -> (CashlyDomain.Category, Int64, Double)? in
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
            return (category, current, median)
        }
        .sorted { Double($0.1) - $0.2 > Double($1.1) - $1.2 }
        guard let first = unusual.first else { return nil }
        let confidence: Provenance.Confidence = previous.count >= 5 ? .high : .medium
        let findings = unusual.map { category, current, median in
            let gap = current - Int64(median.rounded())
            return Finding(
                analysisID: Self.id, topic: .spending, subject: category.id, label: category.name,
                summary:
                    "\(category.name) is \(Formatting.money(gap)) above usual for this point of the month.",
                impact: gap,
                metrics: [
                    .money("current", "So far", minorUnits: current),
                    .money("typical", "Usually", minorUnits: Int64(median.rounded())),
                ],
                recommendation: Recommendation(action: .returnToUsual, monthlySaving: gap),
                confidence: confidence)
        }
        let summary =
            unusual.count == 1
            ? "\(first.0.name) is above usual for this point of the month."
            : "\(unusual.count) categories are above usual for this point of the month."
        return result(
            ledger, summary: summary,
            metrics: [
                Metric(
                    key: "count", label: "Categories", value: Double(unusual.count), unit: .count)
            ],
            series: unusual.prefix(3).map {
                SeriesPoint(label: $0.0.name, value: Double($0.1) / 100, reference: $0.2 / 100)
            },
            findings: findings,
            method:
                "Spending to date compared with the median of recent months, using a robust z-score",
            confidence: confidence)
    }
}
