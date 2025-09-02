//
//  MainAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import CashlyDomain

public enum MainAction: CashlyAction {
    case addBudget(AddBudgetAction)
    case addCategory(AddCategoryAction)
}
