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
    
    @State var addCategoryStore = MockCashlyFactory.shared.makeAddCategoryStore()
    @State var addBudgetStore = MockCashlyFactory.shared.makeAddBudgetStore()
    @State var addTransactionStore = MockCashlyFactory.shared.makeAddTransactionStore()
    @State var addUserStore = MockCashlyFactory.shared.makeAddUserStore()
    @State var addTagStore = MockCashlyFactory.shared.makeAddTagStore()
    @State var mainStore = MockCashlyFactory.shared.makeMainStore()

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
    
    func selectUser() {
        handler(action: .main(.selectUser))
    }
}
