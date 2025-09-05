//
//  AddBudgetAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public enum AddBudgetAction: CashlyAction {
    case fetch
    case save
    case remove
    case stopLoading
    case update(
        categories: [Category],
        id: String,
        amount: Double,
        category: Category?,
        date: Date,
        summary: String,
        isNew: Bool
    )
    case error(CashlyError)
}
