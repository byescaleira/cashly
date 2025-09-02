//
//  BudgetEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData

@Model
public class BudgetEntity {
    @Attribute(.unique) public var id: UUID
    public var amount: Double
    public var category: UUID
    public var date: TimeInterval
    public var summary: String
    
    public init(
        id: UUID,
        amount: Double,
        category: UUID,
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

