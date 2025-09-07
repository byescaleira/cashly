//
//  EnvironmentValues+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyDomain

public extension EnvironmentValues {
    @Entry var addCategoryState = AddCategoryState()
    @Entry var addBudgetState = AddBudgetState()
    @Entry var addTransactionState = AddTransactionState()
    @Entry var addUserState = AddUserState()
    @Entry var mainState = MainState()
    
    @Entry var action: (ApplicationAction) -> Void = { _ in }
}
