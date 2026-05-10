//
//  MockModifier.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import RyzeUI
import RyzeArchitecture
import CashlyPresentation

struct MockModifier: ViewModifier {
    @Environment(\.theme) var theme

    @State var addCategoryStore: CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
    @State var addBudgetStore: CashlyStore<AddBudgetReducer, AddBudgetMiddleware>
    @State var addTransactionStore: CashlyStore<AddTransactionReducer, AddTransactionMiddleware>
    @State var addUserStore: CashlyStore<AddUserReducer, AddUserMiddleware>
    @State var addTagStore: CashlyStore<AddTagReducer, AddTagMiddleware>
    @State var mainStore: CashlyStore<MainReducer, MainMiddleware>

    init() {
        let factory = MockCashlyFactory()
        _addCategoryStore = State(initialValue: factory.makeAddCategoryStore())
        _addBudgetStore = State(initialValue: factory.makeAddBudgetStore())
        _addTransactionStore = State(initialValue: factory.makeAddTransactionStore())
        _addUserStore = State(initialValue: factory.makeAddUserStore())
        _addTagStore = State(initialValue: factory.makeAddTagStore())
        _mainStore = State(initialValue: factory.makeMainStore())
    }

    func body(content: Content) -> some View {
        content
            .environment(addCategoryStore)
            .environment(addBudgetStore)
            .environment(addTransactionStore)
            .environment(addUserStore)
            .environment(addTagStore)
            .environment(mainStore)
        
            .environment(\.addCategoryState, addCategoryStore.state)
            .environment(\.addBudgetState, addBudgetStore.state)
            .environment(\.addTransactionState, addTransactionStore.state)
            .environment(\.addUserState, addUserStore.state)
            .environment(\.addTagState, addTagStore.state)
            .environment(\.mainState, mainStore.state)
        
            .environment(\.action, handler(action:))
    
            .environment(\.isLoading, mainStore.state.isLoading)
            .environment(\.user, mainStore.state.user)
        
            .onChange(of: mainStore.state.filter) { handler(action: .main(.fetch)) }
            .onChange(of: mainStore.state.user) { selectUser() }
        
            .task { handler(action: .main(.fetch)) }
        
            .tint(theme.color.primary)
    }
    
    @MainActor
    func handler(action: ApplicationAction) {
        let stores = (addCategoryStore, addBudgetStore, addTransactionStore, addUserStore, addTagStore, mainStore)
        Task(priority: .high) { @MainActor in
            switch action {
            case let .addCategory(action): await stores.0.dispatch(action: action)
            case let .addBudget(action): await stores.1.dispatch(action: action)
            case let .addTransaction(action): await stores.2.dispatch(action: action)
            case let .addUser(action): await stores.3.dispatch(action: action)
            case let .addTag(action): await stores.4.dispatch(action: action)
            case let .main(action): await stores.5.dispatch(action: action)
            }
        }
    }
    
    func selectUser() {
        handler(action: .main(.selectUser))
    }
}
