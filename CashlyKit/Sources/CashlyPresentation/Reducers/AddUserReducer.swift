//
//  AddUserReducer.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

@MainActor
public struct AddUserReducer: PrismReducer {
    public init() {}

    public func reduce(into state: inout AddUserState, action: AddUserAction) -> PrismEffect<AddUserAction> {
        switch action {
        case .fetch:
            state.isLoading = true
            state.isSaved = false
            state.error = nil
        case .stopLoading: state.isLoading = false
        case let .update(id, name, photo, isNew):
            state.id = id
            state.name = name
            state.photo = photo
            state.isNew = isNew
        case .saved: state.isSaved = true
        case let .error(error): state.error = error
        case let .replace(newState): state = newState
        case .save, .remove: break
        }
        return .none
    }
}
