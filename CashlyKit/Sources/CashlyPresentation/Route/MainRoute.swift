//
//  MainRoute.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import SwiftUI
import CashlyDomain

public enum MainRoute: CashlyRoutable {
    public static func == (lhs: MainRoute, rhs: MainRoute) -> Bool {
        lhs.discriminator == rhs.discriminator
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(discriminator)
    }

    private var discriminator: Int {
        switch self {
        case .addUser: return 0
        case .addCategory: return 1
        case .addBudget: return 2
        case .addTransaction: return 3
        case .addTag: return 4
        case .detailCategory: return 5
        case .category: return 6
        case .transaction: return 7
        case .home: return 8
        case .intelligence: return 9
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
