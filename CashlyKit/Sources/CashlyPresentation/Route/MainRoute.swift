//
//  MainRoute.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import SwiftUI
import RyzeArchitecture
import CashlyDomain

public enum MainRoute: CashlyRoutable {
    public static func == (lhs: MainRoute, rhs: MainRoute) -> Bool {
        switch (lhs, rhs) {
        case (.addUser, .addUser),
            (.addCategory, .addCategory),
            (.addBudget, .addBudget),
            (.category, .category),
            (.transaction, .transaction),
            (.detailCategory, .detailCategory),
            (.home, .home),
            (.intelligence, .intelligence): return true
        default: return false
        }
    }
    
    case addUser(state: AddUserState)
    case addCategory(state: AddCategoryState)
    case addBudget(state: AddBudgetState)
    case addTransaction(state: AddTransactionState)
    case addTag(state: AddTagState)
    case detailCategory(category: CashlyDomain.Category)
    case category
    case transaction
    case home
    case intelligence
    
    public var navigationStyle: CashlyNavigationStyle {
        .push
    }
    
    @ViewBuilder
    public func makeView(content: @escaping (MainRoute) -> any View) -> some View {
        AnyView(content(self))
    }
}
