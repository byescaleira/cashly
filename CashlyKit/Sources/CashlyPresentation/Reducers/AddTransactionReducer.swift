//
//  AddTransactionReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct AddTransactionReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout AddTransactionState, action: AddTransactionAction) -> PrismEffect<AddTransactionAction> {
        switch action {
        case .fetch: state.isLoading = true
        case .stopLoading: state.isLoading = false
        case let .update(
            budgets, id, participants, budget, amount, date, summary, status,
            splitMode, splitValue, tags, isNew, installmentIsOn, installmentPlan
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
            state.installmentIsOn = installmentIsOn
            state.installmentPlan = installmentPlan
        case .saved: state.isSaved = true
        case let .error(error): state.error = error
        case let .replace(newState): state = newState
        case .save, .remove: break
        }
        return .none
    }
}
