//
//  AddUserReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import CashlyDomain

public actor AddUserReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: AddUserState, action: AddUserAction) async -> AddUserState {
        var state = state
        switch action {
        case .fetch:
            state.isLoading = true
        case .stopLoading:
            state.isLoading = false
        case let .update(id, name, photo, isNew):
            state.id = id
            state.name = name
            state.photo = photo
            state.isNew = isNew
        case let .error(error):
            state.error = error
        case .save, .remove:
            break
        }
        return state
    }
}
