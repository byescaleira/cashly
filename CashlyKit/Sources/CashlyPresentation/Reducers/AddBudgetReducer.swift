//
//  AddBudgetReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct AddBudgetReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout AddBudgetState, action: AddBudgetAction) -> PrismEffect<AddBudgetAction> {
        switch action {
        case .fetch: state.isLoading = true
        case .stopLoading: state.isLoading = false
        case let .update(categories, id, amount, category, date, summary, isNew):
            state.categories = categories
            state.id = id
            state.amount = amount
            state.category = category
            state.date = date.string.date(with: .cashly(.yearMonth)) ?? .now
            state.summary = summary
            state.isNew = isNew
        case .saved: state.isSaved = true
        case let .error(error): state.error = error
        case let .replace(newState): state = newState
        case .save, .remove: break
        }
        return .none
    }
}
