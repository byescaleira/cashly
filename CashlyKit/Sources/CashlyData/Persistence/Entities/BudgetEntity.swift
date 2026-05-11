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

    public init(
        id: String,
        amount: Double,
        category: String,
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

