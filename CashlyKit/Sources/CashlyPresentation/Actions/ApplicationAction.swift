//
//  ApplicationAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import CashlyDomain

public enum ApplicationAction: CashlyAction {
    case addCategory(AddCategoryAction)
    case addBudget(AddBudgetAction)
    case addTransaction(AddTransactionAction)
    case addUser(AddUserAction)
    case addTag(AddTagAction)
    case main(MainAction)
}
