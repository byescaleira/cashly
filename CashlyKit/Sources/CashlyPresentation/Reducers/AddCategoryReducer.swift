//
//  AddCategoryReducer.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public actor AddCategoryReducer: CashlyReducer {
    public init() {}
    
    public func reduce(state: AddCategoryState, action: AddCategoryAction) async -> AddCategoryState {
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
        case let .error(error):
            state.error = error
        case .save, .remove:
            break
        }
        return state
    }
}
