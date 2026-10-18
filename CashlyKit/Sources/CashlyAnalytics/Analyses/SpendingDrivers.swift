import CashlyDomain
import Foundation

public struct SpendingDrivers: Analysis {
    public static let id: AnalysisID = "spending-drivers"
    public static let title = "What changed"
    public static let detail =
        "For each category, whether this month's change came from buying more often or paying more each time."
    public static let version = 3

    private let minimumGap: Int64 = 5_000

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let previous = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        guard previous.count >= 3 else { return nil }
        let confidence: Provenance.Confidence = previous.count >= 5 ? .high : .medium
        let now = ledger.expensesByCategory(in: month, throughDay: day)
        let before = previous.map { ledger.expensesByCategory(in: $0, throughDay: day) }
        let findings = ledger.categories.compactMap { category -> Finding? in
            let current = now[category.id] ?? []
            let history = before.map { $0[category.id] ?? [] }
            let spent = current.reduce(0) { $0 + $1.minorUnits }
            let typical =
                Statistics.median(
                    history.map { Double($0.reduce(0) { $0 + $1.minorUnits }) }) ?? 0
            let typicalCount = (Statistics.median(history.map { Double($0.count) }) ?? 0).rounded()
            let difference = Double(spent) - typical
            guard abs(difference) >= Double(minimumGap), abs(difference) >= typical * 0.2
            else { return nil }
            let ticket = current.isEmpty ? 0 : Double(spent) / Double(current.count)
            let pastCharges = history.reduce(0) { $0 + $1.count }
            let pastTotal = history.reduce(0) { $0 + $1.reduce(0) { $0 + $1.minorUnits } }
            let typicalTicket = pastCharges > 0 ? Double(pastTotal) / Double(pastCharges) : 0
            let frequency =
                typicalCount > 0
                ? (Double(current.count) - typicalCount) * typicalTicket : difference
            return Finding(
                analysisID: Self.id, topic: .spending, subject: category.id, label: category.name,
                summary:
                    "\(category.name): \(current.count) charges against a usual \(Int(typicalCount)), \(Formatting.money(Int64(difference.rounded()))) of difference.",
                impact: Int64(difference.rounded()),
                metrics: [
                    .money("current", "So far", minorUnits: spent),
                    .money("typical", "Usually", minorUnits: Int64(typical.rounded())),
                    Metric(
                        key: "count", label: "Charges", value: Double(current.count),
                        unit: .count),
                    Metric(
                        key: "typicalCount", label: "Usual charges", value: typicalCount,
                        unit: .count),
                    .money("ticket", "Average charge", minorUnits: Int64(ticket.rounded())),
                    .money(
                        "typicalTicket", "Usual average charge",
                        minorUnits: Int64(typicalTicket.rounded())),
                    .money("frequency", "From frequency", minorUnits: Int64(frequency.rounded())),
                    .money(
                        "ticketEffect", "From the amount of each charge",
                        minorUnits: Int64((difference - frequency).rounded())),
                ],
                confidence: confidence)
        }
        .sorted {
            abs($0.impact) == abs($1.impact) ? $0.id < $1.id : abs($0.impact) > abs($1.impact)
        }
        guard !findings.isEmpty else { return nil }
        return result(
            ledger,
            summary:
                "\(findings.count) categories changed against the usual for this point of the month.",
            metrics: [
                Metric(
                    key: "count", label: "Categories", value: Double(findings.count), unit: .count)
            ],
            findings: findings,
            method:
                "Spending to date against the median of recent months, split into the change in the number of transactions times the usual average amount of previous months, and the rest as the change in the amount",
            confidence: confidence)
    }
}
