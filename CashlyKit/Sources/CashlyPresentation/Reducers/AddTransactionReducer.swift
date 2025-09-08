//
//  AddTransactionReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import CashlyDomain

public actor AddTransactionReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: AddTransactionState, action: AddTransactionAction) async -> AddTransactionState {
        var state = state
        switch action {
        case .fetch:
            state.isLoading = true
        case .stopLoading:
            state.isLoading = false
        case let .update(
            budgets,
            id,
            participants,
            budget,
            amount,
            date,
            summary,
            status,
            splitMode,
            splitValue,
            tags,
            isNew
        ):
            state.budgets = budgets
            state.id = id
            state.participants = participants
            state.budget = budget
            state.amount = amount
            state.date = date
            state.summary = summary
            state.status = status
            state.splitMode = splitMode
            state.splitValue = splitValue
            state.tags = tags
            state.isNew = isNew
        case let .error(error):
            state.error = error
        case .save, .remove:
            break
        }
        return state
    }
}
