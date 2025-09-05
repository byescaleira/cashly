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
    public var id: String
    public var amount: Double
    public var category: Category?
    public var date: Date
    public var summary: String
    public var isNew: Bool
    public var error: CashlyError?
    
    public var user: User? {
        category?.user
    }
    
    public var canSave: Bool {
        amount > .zero &&
        category != nil &&
        summary.trimmingCharacters(in: .whitespacesAndNewlines).count > 3
    }
    
    public init(
        isLoading: Bool = true,
        categories: [Category] = [],
        id: String = UUID().uuidString,
        amount: Double = .zero,
        category: Category? = nil,
        date: Date = .now,
        summary: String = "",
        isNew: Bool = false,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.categories = categories
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
        self.isNew = isNew
        self.error = error
    }
}
