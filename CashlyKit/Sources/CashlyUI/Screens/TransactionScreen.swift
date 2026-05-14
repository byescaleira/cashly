//
//  TransactionScreen.swift
//  CashlyKit
//
//  //  body + @State only. Rows + toolbar live in
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

    @State var editMode: CashlyEditMode = .inactive
    @State var selection: Set<CashlyDomain.Transaction> = []
    @State var showDeleteAlert = false
    @State var searchText: String = ""

    /// Sections filtered by the active search term. Empty search
    /// returns the cached sections from MainState as-is; otherwise
    /// match the summary OR category name OR budget summary
    /// (case-insensitive).
    var filteredSections: [[CashlyDomain.Transaction]] {
        guard !searchText.isEmpty else { return state.transactionSectionsCache }
        let needle = searchText.lowercased()
        return state.transactionSectionsCache.compactMap { section in
            let matches = section.filter { tx in
                tx.summary.lowercased().contains(needle)
                || tx.effectiveCategory.name.lowercased().contains(needle)
                || (tx.budget?.summary.lowercased().contains(needle) ?? false)
            }
            return matches.isEmpty ? nil : matches
        }
    }

    public init() {}

    public var body: some View {
        CashlyList(selection: $selection) {
            TransactionBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            transactionsSection
        }
        .cashlyEditMode($editMode)
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
        .refreshable {
            action(.main(.fetch))
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
        .searchable(text: $searchText, prompt: CashlyL10n.string("Search transactions"))
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
