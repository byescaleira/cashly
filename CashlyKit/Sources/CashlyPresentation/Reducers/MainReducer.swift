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
        case let .update(budgets, categories, transactions, tags, users):
            state.budgets = budgets
            state.categories = categories
            state.transactions = transactions
            state.tags = tags
            state.users = users
        case let .removeTag(tag):
            state.tags = state.tags.filter { $0.id != tag.id }
            state.filter.tags = Set(state.tags.filter { $0.id != tag.id })
        case let .removeBudget(budget):
            state.budgets = state.budgets.filter { $0.id != budget.id }
        case let .removeCategory(category):
            state.categories = state.categories.filter { $0.id != category.id }
            state.filter.categories = Set(state.categories.filter { $0.id != category.id })
        case let .removeUser(user):
            state.users = state.users.filter { $0.id != user.id }
            state.filter.users = Set(state.users.filter { $0.id != user.id })
        case let .removeTransaction(transaction):
            state.transactions = state.transactions.filter { $0.id != transaction.id }
        case let .error(error):
            state.error = error
        }
        return state
    }
}
