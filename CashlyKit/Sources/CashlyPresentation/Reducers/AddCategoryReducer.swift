//
//  AddCategoryReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct AddCategoryReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout AddCategoryState, action: AddCategoryAction) -> PrismEffect<AddCategoryAction> {
        switch action {
        case .fetch:
            state.isLoading = true
            state.isSaved = false
            state.error = nil
        case .stopLoading: state.isLoading = false
        case let .update(id, user, name, color, icon, isNew):
            state.id = id
            state.user = user
            state.name = name
            state.color = color
            state.icon = icon
            state.isNew = isNew
        case .saved: state.isSaved = true
        case let .error(error): state.error = error
        case let .replace(newState): state = newState
        case .save, .remove: break
        }
        return .none
    }
}
