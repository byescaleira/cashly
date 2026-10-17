import CashlyDomain
import Foundation

public enum BudgetRule {
    public static func monthlyTotals(_ ledger: LedgerSnapshot, before month: YearMonth)
        -> [String: [Int64]]
    {
        (1...6).reduce(into: [String: [Int64]]()) { totals, offset in
            let past = month.adding(months: -offset)
            let byCategory = ledger.postings(in: past).filter(\.isExpense)
                .reduce(into: [String: Int64]()) { $0[$1.categoryID, default: 0] += $1.minorUnits }
            for (categoryID, total) in byCategory where total > 0 {
                totals[categoryID, default: []].append(total)
            }
        }
    }

    public static func suggested(_ totals: [Int64]) -> Int64? {
        guard let median = Statistics.median(totals.map(Double.init)), median > 0 else {
            return nil
        }
        return Int64((median / 1_000).rounded(.up)) * 1_000
    }
}
