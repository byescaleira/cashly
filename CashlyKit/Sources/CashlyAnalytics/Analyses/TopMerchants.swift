import CashlyDomain
import Foundation

public struct TopMerchants: Analysis {
    public static let id: AnalysisID = "top-merchants"
    public static let title = "Repeat purchases"
    public static let detail =
        "Descriptions you repeat most in the last three months, grouped by name, with the monthly average."
    public static let version = 1

    private let window = 90

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let covered = ledger.coveredDays(lastDays: window)
        guard covered >= 30 else { return nil }
        let groups = Dictionary(grouping: ledger.purchases(lastDays: window)) {
            MerchantMemory.key(for: $0.summary)
        }
        let findings = groups.compactMap { key, postings -> Finding? in
            guard !key.isEmpty, postings.count >= 2 else { return nil }
            let total = postings.reduce(0) { $0 + $1.minorUnits }
            let monthly = Int64((Double(total) * 30 / Double(covered)).rounded())
            let names = Dictionary(grouping: postings, by: \.summary)
            let label =
                names.max {
                    $0.value.count == $1.value.count
                        ? ($0.value.map(\.date).max() ?? .distantPast)
                            < ($1.value.map(\.date).max() ?? .distantPast)
                        : $0.value.count < $1.value.count
                }?.key ?? key
            return Finding(
                analysisID: Self.id, topic: .spending, subject: key, label: label,
                summary:
                    "\(label): \(postings.count) times in the last \(covered) days, about \(Formatting.money(monthly)) a month.",
                impact: monthly,
                metrics: [
                    .money("total", "Total", minorUnits: total),
                    .money("monthly", "Per month", minorUnits: monthly),
                    .money("ticket", "Average charge", minorUnits: total / Int64(postings.count)),
                    Metric(
                        key: "count", label: "Times", value: Double(postings.count), unit: .count),
                    Metric(key: "days", label: "Days", value: Double(covered), unit: .days),
                ],
                confidence: covered >= window ? .high : .medium)
        }
        .sorted { $0.impact == $1.impact ? $0.id < $1.id : $0.impact > $1.impact }
        guard let first = findings.first else { return nil }
        return result(
            ledger, summary: "\(first.label) is the purchase you repeat most.",
            metrics: [
                Metric(key: "days", label: "Days", value: Double(covered), unit: .days)
            ],
            findings: Array(findings.prefix(5)),
            method:
                "One-off purchases of the last 90 days grouped by normalized description, repeated at least twice",
            confidence: covered >= window ? .high : .medium)
    }
}
