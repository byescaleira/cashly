//
//  Budget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public struct Budget: CashlyEntity, Sendable {
    public var id: UUID
    public var amount: Double
    public var category: Category
    public var date: Date
    public var summary: String
    
    public init(
        id: UUID,
        amount: Double,
        category: Category,
        date: Date,
        summary: String
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
    }
}
