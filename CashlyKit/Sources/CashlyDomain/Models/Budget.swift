//
//  Budget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

/// Monthly spending allowance for a category.
///
/// `date` is a packed `YYYYMM` integer (e.g. `202604`) — Cashly uses
/// this format throughout for month-bucketing without timezone churn.
public struct Budget: CashlyEntity, Sendable {
    public var id: String
    public var amount: Double
    public var category: Category
    /// Packed `YYYYMM` integer (e.g. `202604` for April 2026).
    public var date: Int
    public var summary: String
    /// K9: when `true`, any unspent amount from this budget's
    /// previous month rolls into the current month's effective
    /// allowance. Opt-in per budget — defaults to false so legacy
    /// behavior is preserved.
    public var rollsOver: Bool

    /// Owning user, inherited from the category.
    public var user: User { category.user }

    public init(
        id: String,
        amount: Double,
        category: Category,
        date: Int,
        summary: String,
        rollsOver: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
        self.rollsOver = rollsOver
    }
}

public extension Budget {
    /// Previous yearMonth in packed YYYYMM form, rolling back across
    /// January (e.g. 202601 → 202512).
    var previousYearMonth: Int {
        let year = date / 100
        let month = date % 100
        if month == 1 { return (year - 1) * 100 + 12 }
        return year * 100 + (month - 1)
    }
}

extension Budget: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, amount, category, date, summary, rollsOver
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.amount = try c.decode(Double.self, forKey: .amount)
        self.category = try c.decode(Category.self, forKey: .category)
        self.date = try c.decode(Int.self, forKey: .date)
        self.summary = try c.decode(String.self, forKey: .summary)
        self.rollsOver = try c.decodeIfPresent(Bool.self, forKey: .rollsOver) ?? false
    }
}
