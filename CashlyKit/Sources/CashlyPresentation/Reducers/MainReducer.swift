//
//  MainReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct MainReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout MainState, action: MainAction) -> PrismEffect<MainAction> {
        switch action {
        case .fetch: state.isLoading = true
        case .stopLoading: state.isLoading = false
        case let .update(filter, budgets, categories, transactions, tags, users, user, predictedTransactionsAmount):
            state.filter = filter
            state.budgets = budgets
            state.categories = categories
            state.transactions = transactions
            state.tags = tags
            state.users = users
            state.user = user
            state.predictedTransactionsAmount = predictedTransactionsAmount
        case let .removeTag(tag):
            state.tags = state.tags.filter { $0.id != tag.id }
            state.filter.tags = Set(state.tags.filter { $0.id != tag.id })
        case let .removeTransaction(transaction):
            state.transactions = state.transactions.filter { $0.id != transaction.id }
        case let .removeTransactions(transactions):
            state.transactions = state.transactions.filter { !transactions.contains($0) }
        case let .error(error): state.error = error
        case let .replace(newState): state = newState
        case .selectUser, .fetchPredictions: break
        }
        return .none
    }
}
