//
//  AddCategoryAction.swift
//  CashlyKit
//

import CashlyDomain

public enum AddCategoryAction: CashlyAction, CashlyReplaceableAction {
    public typealias State = AddCategoryState

    case fetch
    case save
    case remove
    case stopLoading
    case update(
        id: String,
        user: User?,
        name: String,
        color: String,
        icon: String,
        isNew: Bool
    )
    case saved
    case error(CashlyError)
    case replace(AddCategoryState)
}
