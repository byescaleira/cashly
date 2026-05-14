//
//  BudgetEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData

@Model
public class BudgetEntity {
    public var id: String = ""
    public var amount: Double = 0
    public var category: String = ""
    public var date: Int = 0
    public var summary: String = ""
    /// K9: when true, leftover from previous month carries into
    /// this budget's effective allowance. Defaults to false so
    /// pre-K9 rows preserve their behavior.
    public var rollsOver: Bool = false

    public init(
        id: String,
        amount: Double,
        category: String,
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

