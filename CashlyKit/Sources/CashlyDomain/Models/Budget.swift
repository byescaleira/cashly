//
//  Budget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public struct Budget: CashlyEntity, Sendable {
    public var id: String
    public var amount: Double
    public var category: Category
    public var date: Int
    public var summary: String
    
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
