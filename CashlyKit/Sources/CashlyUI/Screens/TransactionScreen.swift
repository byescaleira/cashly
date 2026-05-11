//
//  TransactionScreen.swift
//  CashlyKit
//
//  Wave 7 G019: body + @State only. Rows + toolbar live in
//  TransactionScreen+*.swift.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct TransactionScreen: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store

    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router

    @State var editMode = EditMode.inactive
    @State var selection: Set<CashlyDomain.Transaction> = []
    @State var showDeleteAlert = false

    public init() {}

    public var body: some View {
        CashlyList(selection: $selection) {
            TransactionBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            transactionsSection
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if editMode != .active {
                    UserItemView()
                }
                selectAllButton
            }

            ToolbarItemGroup {
                editButton
                FilterItemView()
            }

            ToolbarSpacer(.fixed)
            ToolbarItemGroup {
                addButton

                shareButton
                removeButton
                checkButton
            }
        }
        .environment(\.isLoading, state.isLoading)
        .onAppear { action(.main(.fetch)) }
        .navigationTitle(CashlyL10n.string("Transactions"))
    }

    public static var mock: some View {
        TransactionScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        TransactionScreen
            .cashlyPreview()
    }
}
#endif
