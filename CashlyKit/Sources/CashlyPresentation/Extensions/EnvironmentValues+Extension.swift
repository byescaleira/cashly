//
//  EnvironmentValues+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyDomain

public extension EnvironmentValues {
    @Entry var addCategoryState = AddCategoryState.new()
    @Entry var addBudgetState = AddBudgetState.new()
    @Entry var addTransactionState = AddTransactionState.new()
    @Entry var addUserState = AddUserState.new()
    @Entry var addTagState = AddTagState.new()
    @Entry var mainState = MainState()
    @Entry var paywallState = PaywallState()

    @Entry var router: CashlyRouter<MainRoute> = .init()
    @Entry var action: (ApplicationAction) -> Void = { _ in }
    /// Deeplink hand-off slot. CashlyApp writes here from
    /// `onOpenURL`; MainScreen observes and forwards into the active
    /// tab router. Nil otherwise.
    @Entry var pendingDeeplink: MainRoute? = nil

    @Entry var user: User?
}
