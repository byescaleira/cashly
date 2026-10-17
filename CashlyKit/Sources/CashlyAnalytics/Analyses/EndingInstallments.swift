import CashlyDomain
import Foundation

public struct EndingInstallments: Analysis {
    public static let id: AnalysisID = "ending-installments"
    public static let title = "Installments ending"
    public static let detail =
        "How much of the monthly budget frees up when installment plans end in the next three months."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let plans = Dictionary(
            grouping: ledger.postings.filter { $0.isExpense && $0.installments > 1 },
            by: \.transactionID)
        let ends = plans.compactMap { id, postings -> (YearMonth, Int64, String)? in
            guard let last = postings.max(by: { $0.month < $1.month }),
                last.month >= month, last.month < month.adding(months: 3)
            else { return nil }
            return (last.month.adding(months: 1), last.minorUnits, id)
        }
        let freed = Dictionary(grouping: ends, by: \.0)
        let findings = freed.keys.sorted().map { free in
            let amount = freed[free, default: []].reduce(0) { $0 + $1.1 }
            return Finding(
                analysisID: Self.id, topic: .upcoming, subject: "\(free.rawValue)",
                label: Formatting.month(free),
                summary:
                    "From \(Formatting.month(free)), \(Formatting.money(amount)) a month is free of installments.",
                impact: amount,
                metrics: [
                    .money("freed", "Frees up", minorUnits: amount),
                    Metric(
                        key: "month", label: "From", value: Double(free.rawValue), unit: .month),
                    Metric(
                        key: "plans", label: "Plans", value: Double(freed[free, default: []].count),
                        unit: .count),
                ],
                confidence: .certain)
        }
        guard !findings.isEmpty else { return nil }
        return result(
            ledger,
            summary: "\(ends.count) installment plans end in the next three months.",
            metrics: [
                Metric(key: "plans", label: "Plans", value: Double(ends.count), unit: .count)
            ],
            findings: findings,
            method:
                "Installment plans whose last installment falls this month or in the next two; the amount frees up the month after",
            confidence: .certain,
            evidence: ends.map(\.2).sorted())
    }
}
