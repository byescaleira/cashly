//
//  AddTagReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 10/09/25.
//

import CashlyDomain

public actor AddTagReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: AddTagState, action: AddTagAction) async -> AddTagState {
        var state = state
        switch action {
        case .fetch:
            state.isLoading = true
        case .stopLoading:
            state.isLoading = false
        case let .update(id, user, name, color, icon, isNew):
            state.id = id
            state.user = user
            state.name = name
            state.color = color
            state.icon = icon
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
