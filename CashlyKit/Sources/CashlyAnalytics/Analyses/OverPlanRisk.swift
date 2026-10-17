import CashlyDomain
import Foundation

public struct OverPlanRisk: Analysis {
    public static let id: AnalysisID = "over-plan-risk"
    public static let title = "Chance of going over plan"
    public static let detail =
        "How likely the month is to end over plan: the month forecast plus how much your daily spending usually varies, simulated many times."
    public static let version = 3

    private let runs = 2_000
    private let window = 91

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let budgeted = ledger.budgeted(in: month)
        let calendar = CashlyCalendar.current
        let left = month.dayCount - calendar.component(.day, from: ledger.today)
        let covered = ledger.coveredDays(lastDays: window)
        guard budgeted > 0, left > 0, covered >= 28, let projection = MonthPace.projection(ledger)
        else { return nil }
        let recurring = Set(
            (RecurringCharges().run(ledger)?.findings ?? []).map {
                String($0.subject.prefix { $0 != "|" })
            })
        let byDay = Dictionary(
            grouping: ledger.purchases(lastDays: covered).filter {
                !recurring.contains(MerchantMemory.key(for: $0.summary))
            }
        ) { calendar.startOfDay(for: $0.date) }.mapValues { $0.reduce(0) { $0 + $1.minorUnits } }
        let pool = (1..<covered).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: ledger.startOfToday)
        }.map { Double(byDay[$0] ?? 0) }
        var generator = SeededGenerator(text: "\(ledger.revision)|\(month.rawValue)|\(left)")
        let draws = (0..<runs).map { _ in
            (0..<left).reduce(0.0) { sum, _ in sum + (pool.randomElement(using: &generator) ?? 0) }
        }
        let center = draws.sorted()[runs / 2]
        let floor = Double(projection.spent + projection.scheduled)
        let totals = draws.map { max(Double(projection.projected) + $0 - center, floor) }.sorted()
        let probability = Double(totals.filter { $0 > Double(budgeted) }.count) / Double(runs)
        return result(
            ledger,
            summary:
                "\(Int((probability * 100).rounded()))% chance of ending the month over the plan of \(Formatting.money(budgeted)).",
            metrics: [
                Metric(key: "probability", label: "Chance", value: probability, unit: .ratio),
                .money("projected", "Month forecast", minorUnits: projection.projected),
                .money(
                    "high", "Bad case close",
                    minorUnits: Int64((Statistics.quantile(totals, 0.9) ?? 0).rounded())),
                .money("budgeted", "Planned", minorUnits: budgeted),
                Metric(key: "runs", label: "Simulations", value: Double(runs), unit: .count),
            ],
            method:
                "The month forecast plus the deviation from the upper median of \(left) days drawn at random from the daily totals of purchases without installments and without recurring charges in the previous \(covered - 1) days, repeated \(runs) times; never below what already went out plus scheduled bills",
            confidence: covered >= window ? .medium : .low)
    }
}
