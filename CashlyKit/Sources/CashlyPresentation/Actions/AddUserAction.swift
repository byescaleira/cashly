//
//  AddUserAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import CashlyDomain

public enum AddUserAction: CashlyAction {
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
    case error(CashlyError)
}
