import CashlyDomain
import Foundation

public struct MonthlySeries: Equatable, Sendable {
    public let values: [YearMonth: Int64]

    public init(values: [YearMonth: Int64]) {
        self.values = values
    }

    public init(_ postings: [Posting], value: (Posting) -> Int64?) {
        var values: [YearMonth: Int64] = [:]
        for posting in postings {
            if let amount = value(posting) { values[posting.month, default: 0] += amount }
        }
        self.values = values
    }

    public static func expenses(_ postings: [Posting], categoryID: String? = nil) -> MonthlySeries {
        MonthlySeries(postings) { posting in
            guard posting.isExpense, categoryID == nil || posting.categoryID == categoryID else {
                return nil
            }
            return posting.minorUnits
        }
    }

    public subscript(month: YearMonth) -> Int64 { values[month] ?? 0 }

    public func window(endingBefore month: YearMonth, count: Int) -> [Int64] {
        (1...max(count, 1)).map { self[month.adding(months: -$0)] }
    }

    public func months(from start: YearMonth, to end: YearMonth) -> [YearMonth] {
        guard start <= end else { return [] }
        return (0...end.months(since: start)).map { start.adding(months: $0) }
    }
}
