//
//  AddBudgetReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public actor AddBudgetReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: AddBudgetState, action: AddBudgetAction) async -> AddBudgetState {
        var state = state
        switch action {
        case .fetch:
            state.isLoading = true
        case .stopLoading:
            state.isLoading = false
        case let .update(categories, id, amount, category, date, summary, isNew):
            state.categories = categories
            state.id = id
            state.amount = amount
            state.category = category
            state.date = date.string.date(with: .cashly(.yearMonth)) ?? .now
            state.summary = summary
            state.isNew = isNew
        case .saved:
            state.isSaved = true
        case let .error(error):
            state.error = error
        case .save, .remove:
            break
        }
        return state
    }
}
