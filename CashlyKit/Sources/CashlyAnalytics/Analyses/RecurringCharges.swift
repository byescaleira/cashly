import CashlyDomain
import Foundation

public struct RecurringCharges: Analysis {
    public static let id: AnalysisID = "recurring-charges"
    public static let title = "Recurring charges"
    public static let detail =
        "Charges with the same description and a similar amount every month, like subscriptions and fixed bills, with what they cost in a year."
    public static let version = 1

    private let tolerance = 0.15
    private let grace = 10

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let groups = Dictionary(grouping: ledger.purchases(lastDays: 180)) {
            MerchantMemory.key(for: $0.summary)
        }
        let findings = groups.flatMap { key, postings -> [Finding] in
            guard !key.isEmpty else { return [] }
            let accepted = bands(of: postings).filter { isRecurring($0, ledger: ledger) }
            return accepted.compactMap { band in
                finding(
                    for: band,
                    subject: accepted.count > 1 ? "\(key)|\(latest(of: band).minorUnits)" : key,
                    ledger: ledger)
            }
        }
        .sorted { $0.impact == $1.impact ? $0.id < $1.id : $0.impact > $1.impact }
        guard !findings.isEmpty else { return nil }
        let monthly = findings.reduce(0) { $0 + $1.impact }
        return result(
            ledger,
            summary:
                "\(findings.count) recurring charges add up to \(Formatting.money(monthly * 12)) a year.",
            metrics: [
                .money("monthly", "Per month", minorUnits: monthly),
                .money("yearly", "Per year", minorUnits: monthly * 12),
                Metric(key: "count", label: "Charges", value: Double(findings.count), unit: .count),
            ],
            findings: findings,
            method:
                "Purchases without installments of the last 180 days grouped by normalized description and by amount bands within 15%, in at least three months, about one a month, 24 to 38 days apart with at most one skipped month (52 to 70 days), expected again within 10 days from today; the monthly amount is the latest charge",
            confidence: findings.allSatisfy { $0.confidence == .high } ? .high : .medium)
    }

    private func bands(of postings: [Posting]) -> [[Posting]] {
        postings.sorted { $0.minorUnits < $1.minorUnits }.reduce(into: [[Posting]]()) {
            bands, posting in
            if let first = bands.last?.first,
                Double(posting.minorUnits) <= Double(first.minorUnits) * (1 + tolerance)
            {
                bands[bands.count - 1].append(posting)
            } else {
                bands.append([posting])
            }
        }
    }

    private func latest(of band: [Posting]) -> Posting {
        band.max { $0.date < $1.date } ?? band[0]
    }

    private func isRecurring(_ band: [Posting], ledger: LedgerSnapshot) -> Bool {
        let calendar = CashlyCalendar.current
        let dates = band.map { calendar.startOfDay(for: $0.date) }.sorted()
        let intervals = zip(dates, dates.dropFirst()).map {
            calendar.dateComponents([.day], from: $0, to: $1).day ?? 0
        }
        let regular = intervals.filter { (24...38).contains($0) }.count
        let skipped = intervals.filter { (52...70).contains($0) }.count
        let months = Set(band.map(\.month)).count
        guard months >= 3, band.count <= months + 1, skipped <= 1,
            regular + skipped == intervals.count,
            let next = calendar.date(byAdding: .month, value: 1, to: latest(of: band).date),
            let limit = calendar.date(byAdding: .day, value: grace, to: next)
        else { return false }
        return limit >= ledger.startOfToday
    }

    private func finding(for band: [Posting], subject: String, ledger: LedgerSnapshot)
        -> Finding?
    {
        let calendar = CashlyCalendar.current
        let months = Set(band.map(\.month))
        let last = latest(of: band)
        guard let next = calendar.date(byAdding: .month, value: 1, to: last.date) else {
            return nil
        }
        let monthly = last.minorUnits
        let days = max(
            calendar.dateComponents(
                [.day], from: ledger.startOfToday, to: calendar.startOfDay(for: next)
            ).day ?? 0, 0)
        return Finding(
            analysisID: Self.id, topic: .saving, subject: subject, label: last.summary,
            summary:
                "\(last.summary) repeats every month for \(Formatting.money(monthly)), \(Formatting.money(monthly * 12)) a year.",
            impact: monthly,
            metrics: [
                .money("monthly", "Per month", minorUnits: monthly),
                .money("yearly", "Per year", minorUnits: monthly * 12),
                Metric(key: "months", label: "Months", value: Double(months.count), unit: .count),
                Metric(key: "nextIn", label: "Next in", value: Double(days), unit: .days),
            ],
            recommendation: Recommendation(action: .review, monthlySaving: monthly),
            confidence: months.count >= 4 ? .high : .medium)
    }
}
