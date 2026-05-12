//
//  AddCategoryScreen.swift
//  CashlyKit
//
//  Shell + state for the add/edit-category flow. Sections live in
//  AddCategoryScreen+Sections, subviews in +Subviews, toolbar in
//  +Toolbar.
//

import SwiftUI
import CashlyResource
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyPresentation

public struct AddCategoryScreen: CashlyView {
    @Environment(CashlyStore<AddCategoryState, AddCategoryAction>.self) var store

    @Environment(\.addCategoryState) var state
    @Environment(\.mainState) var mainState
    @Environment(\.action) var action
    @Environment(\.router) var router

    @State var category: CashlySymbolCategory = .food

    var initialState: AddCategoryState?

    public init(initialState: AddCategoryState? = nil) {
        self.initialState = initialState
    }

    public var body: some View {
        Form {
            infoSection
            nameSection
            iconCategorySection
        }
        .toolbar {
            ToolbarItemGroup {
                UserItemView()
                usageItem
                removeButton
                saveButton
            }
        }
        .onChange(of: state.isLoading) { setIcon() }
        .onChange(of: state.icon) { onChangeIcon() }
        .task { await handlerInitialState() }
        .scrollDismissesKeyboard(.immediately)
        .cashlyDismiss(isSaved: state.isSaved)
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .onDisappear { store.cancelEffects() }
        .environment(\.isLoading, state.isLoading)
    }

    func handlerInitialState() async {
        if let initialState {
            store.cashlyReplace(initialState)
        }
        await Task.yield()
        action(.addCategory(.fetch))
    }

    func onChangeIcon() {
        guard !state.isNew else { return }
        category = CashlySymbolCategory.allCases.first(where: {
            $0.symbols.contains(state.icon)
        }) ?? .food
    }

    func setIcon() {
        guard !state.isLoading && state.isNew && state.icon.isEmpty else { return }
        store.cashlyMutate(\.icon, category.symbols.first ?? "")
    }

    public static var mock: some View {
        AddCategoryScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddCategoryScreen
            .cashlyPreview()
    }
}
#endif
