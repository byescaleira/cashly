//
//  AddCategoryAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyDomain

public enum AddCategoryAction: CashlyAction {
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
