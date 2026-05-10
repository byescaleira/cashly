//
//  CashlyApp.swift
//  Cashly
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftUI
import SwiftData

import RyzeUI
import RyzeArchitecture
import RyzeIntelligence

import CashlyDomain
import CashlyData
import CashlyPresentation
import CashlyUI
#if DEBUG || targetEnvironment(simulator)
import CashlyMock
#endif

@main
struct CashlyApp: App {
    @Environment(\.theme) var theme

    @State var addCategoryStore: CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
    @State var addBudgetStore: CashlyStore<AddBudgetReducer, AddBudgetMiddleware>
    @State var addTransactionStore: CashlyStore<AddTransactionReducer, AddTransactionMiddleware>
    @State var addUserStore: CashlyStore<AddUserReducer, AddUserMiddleware>
    @State var addTagStore: CashlyStore<AddTagReducer, AddTagMiddleware>
    @State var mainStore: CashlyStore<MainReducer, MainMiddleware>

    init() {
        let factory: CashlyPresentationFactory
        do {
            factory = try CashlyPresentationFactory()
        } catch {
            preconditionFailure("Failed to bootstrap CashlyPresentationFactory: \(error.localizedDescription)")
        }
        _addCategoryStore = State(initialValue: factory.makeAddCategoryStore())
        _addBudgetStore = State(initialValue: factory.makeAddBudgetStore())
        _addTransactionStore = State(initialValue: factory.makeAddTransactionStore())
        _addUserStore = State(initialValue: factory.makeAddUserStore())
        _addTagStore = State(initialValue: factory.makeAddTagStore())
        _mainStore = State(initialValue: factory.makeMainStore())
    }

    var body: some Scene {
        WindowGroup {
            MainScreen()
                #if targetEnvironment(simulator)
                .cashlyPreview()
                #else
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
                .onChange(of: mainStore.state.user) { handler(action: .main(.selectUser)) }
            
                .task { handler(action: .main(.fetch)) }
            
                .tint(theme.color.primary)
                #endif
        }
    }
    
    func handler(action: ApplicationAction) {
        Task(priority: .high) { @MainActor in
            switch action {
            case let .addCategory(action): try await addCategoryStore.dispatch(action: action)
            case let .addBudget(action): try await addBudgetStore.dispatch(action: action)
            case let .addTransaction(action): try await addTransactionStore.dispatch(action: action)
            case let .addUser(action): return try await addUserStore.dispatch(action: action)
            case let .addTag(action): return try await addTagStore.dispatch(action: action)
            case let .main(action): try await mainStore.dispatch(action: action)
            }
        }
    }
}
