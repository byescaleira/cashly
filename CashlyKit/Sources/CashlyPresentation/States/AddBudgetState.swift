//
//  AddBudgetState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public struct AddBudgetState: CashlyState {
    public var isLoading: Bool
    public var categories: [Category]
    public var id: UUID
    public var amount: Double
    public var category: Category?
    public var date: Date
    public var summary: String
    public var error: CashlyError?
    
    public init(
        isLoading: Bool = true,
        categories: [Category] = [],
        id: UUID = .init(),
        amount: Double = .zero,
        category: Category? = nil,
        date: Date = .now,
        summary: String = "",
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.categories = categories
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
        self.error = error
    }
}
