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

    /// Owning user, inherited from the category.
    public var user: User { category.user }

    public init(
        id: String,
        amount: Double,
        category: Category,
        date: Int,
        summary: String
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
    }
}
