//
//  AddTagAction.swift
//  CashlyKit
//

import CashlyDomain

public enum AddTagAction: CashlyAction, CashlyReplaceableAction {
    public typealias State = AddTagState

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
    case replace(AddTagState)
}
