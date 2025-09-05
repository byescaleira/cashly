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
    public var date: TimeInterval
    public var summary: String
    
    public init(
        id: String,
        amount: Double,
        category: String,
        date: TimeInterval,
        summary: String
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
    }
}

