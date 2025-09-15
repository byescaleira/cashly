//
//  AddTagAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 10/09/25.
//

import CashlyDomain

public enum AddTagAction: CashlyAction {
    case fetch
    case save
    case remove
    case stopLoading
    case update(
        id: String,
        user: User?,
        name: String,
        color: Color,
        icon: String,
        isNew: Bool
    )
    case saved
    case error(CashlyError)
}
