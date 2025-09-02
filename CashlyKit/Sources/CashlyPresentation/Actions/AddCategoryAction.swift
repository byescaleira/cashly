//
//  AddCategoryAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public enum AddCategoryAction: CashlyAction {
    case fetch
    case save
    case remove
    case stopLoading
    case update(
        id: UUID,
        name: String,
        color: String,
        icon: String
    )
    case error(CashlyError)
}
