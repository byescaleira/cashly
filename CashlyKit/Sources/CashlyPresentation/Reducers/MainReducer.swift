//
//  MainReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import CashlyDomain

public actor MainReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: MainState, action: MainAction) async -> MainState {
        var state = state
        switch action {
        case .fetch:
            state.isLoading = true
        case .stopLoading:
            state.isLoading = false
        case let .update(filter, budgets, categories, transactions, tags, users, user):
            state.filter = filter
            state.budgets = budgets
            state.categories = categories
            state.transactions = transactions
            state.tags = tags
            state.users = users
            state.user = user
        case let .removeTag(tag):
            state.tags = state.tags.filter { $0.id != tag.id }
            state.filter.tags = Set(state.tags.filter { $0.id != tag.id })
        case let .removeTransaction(transaction):
            state.transactions = state.transactions.filter { $0.id != transaction.id }
        case let .error(error):
            state.error = error
        case .selectUser:
            break
        }
        return state
    }
}
