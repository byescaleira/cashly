//
//  EnvironmentValues+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyDomain

public extension EnvironmentValues {
    @Entry var addBudgetState = AddBudgetState()
    @Entry var addCategoryState = AddCategoryState()
}
