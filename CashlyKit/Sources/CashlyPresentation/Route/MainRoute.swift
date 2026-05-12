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
        lhs.identity == rhs.identity
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identity.discriminator)
        hasher.combine(identity.payloadId)
    }

    /// Stable identity for this route: discriminator (which case) plus
    /// a payload id (the AddXState.id or Category.id when relevant).
    /// Previous implementation hashed only the discriminator, so two
    /// `.addTransaction(state: A)` and `.addTransaction(state: B)`
    /// pushes hashed identical — NavigationStack saw them as the same
    /// destination and corrupted the back stack.
    private var identity: (discriminator: Int, payloadId: String) {
        switch self {
        case let .addUser(state):
            return (0, state.id)
        case let .addCategory(state):
            return (1, state.id)
        case let .addBudget(state):
            return (2, state.id)
        case let .addTransaction(state):
            return (3, state.id)
        case let .addTag(state):
            return (4, state.id)
        case let .detailCategory(category):
            return (5, category.id)
        case .category:
            return (6, "")
        case .transaction:
            return (7, "")
        case .home:
            return (8, "")
        case .intelligence:
            return (9, "")
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
