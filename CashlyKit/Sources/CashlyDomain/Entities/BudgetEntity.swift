//
//  BudgetEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData

@Model
public class BudgetEntity {
    @Attribute(.unique) public var id: String
    public var amount: Double
    public var category: String
    public var date: Int
    public var summary: String
    
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

