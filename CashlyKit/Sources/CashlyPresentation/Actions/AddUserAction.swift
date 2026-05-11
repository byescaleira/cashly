//
//  AddUserAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import CashlyDomain

public enum AddUserAction: CashlyAction, CashlyReplaceableAction {
    public typealias State = AddUserState

    case fetch
    case save
    case remove
    case stopLoading
    case update(
        id: String,
        name: String,
        photo: String?,
        isNew: Bool
    )
    case saved
    case error(CashlyError)
    case replace(AddUserState)
}
