//
//  AddTagScreen.swift
//  CashlyKit
//
//  Shell + state for the add/edit-tag flow. Form sections live in
//  AddTagScreen+Sections, reusable subviews in +Subviews, toolbar
//  items in +Toolbar.
//

import SwiftUI
import CashlyResource
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyPresentation

public struct AddTagScreen: CashlyView {
    @Environment(CashlyStore<AddTagState, AddTagAction>.self) var store

    @Environment(\.addTagState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router

    @State var category: CashlySymbolCategory = .random

    var initialState: AddTagState?

    public init(initialState: AddTagState? = nil) {
        self.initialState = initialState
    }

    public var body: some View {
        Form {
            infoSection
            nameSection
            iconTagSection
        }
        .toolbar {
            ToolbarItemGroup {
                UserItemView()
                removeButton
                saveButton
            }
        }
        .onChange(of: state.isLoading) { setIcon() }
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
        action(.addTag(.fetch))
    }

    func setIcon() {
        guard !state.isLoading && state.isNew && state.icon.isEmpty else { return }
        store.cashlyMutate(\.icon, category.symbols.first ?? "")
    }

    public static var mock: some View {
        AddTagScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddTagScreen
            .cashlyPreview()
    }
}
#endif
