//
//  AddBudgetState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import Foundation
import CashlyDomain

public struct AddBudgetState: CashlyState {
    public var isLoading: Bool
    public var categories: [CashlyDomain.Category]
    public var id: String
    public var amount: Double
    public var category: CashlyDomain.Category?
    public var date: Date
    public var summary: String
    public var isNew: Bool
    public var isSaved: Bool = false
    public var error: CashlyError?
    /// K9b: toggle that controls whether leftover from the previous
    /// month rolls into this budget's effective allowance.
    public var rollsOver: Bool = false

    public var user: User? {
        category?.user
    }

    public var canSave: Bool {
        amount > .zero &&
        category != nil &&
        summary.trimmingCharacters(in: .whitespacesAndNewlines).count > 3
    }

    public var yearMonth: Int {
        date.timeIntervalSince1970.yearMonth
    }

    private init(
        isLoading: Bool = true,
        categories: [CashlyDomain.Category] = [],
        id: String = UUID().uuidString,
        amount: Double = .zero,
        category: CashlyDomain.Category? = nil,
        date: Date = .now,
        summary: String = "",
        isNew: Bool = true,
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

    public static func new() -> AddBudgetState {
        AddBudgetState()
    }

    public static func new(category: CashlyDomain.Category, date: Date) -> AddBudgetState {
        AddBudgetState(category: category, date: date)
    }

    public static func edit(id: String) -> AddBudgetState {
        AddBudgetState(id: id, isNew: false)
    }
}
