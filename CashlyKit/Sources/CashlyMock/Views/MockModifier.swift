//
//  MockModifier.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import RyzeUI
import CashlyPresentation

struct MockModifier: ViewModifier {
    @StateObject var addBudgetStore = CashlyPresentationFactory().makeAddBudgetStore()
    @StateObject var addCategoryStore = CashlyPresentationFactory().makeAddCategoryStore()
    
    func body(content: Content) -> some View {
        content
            .environmentObject(addBudgetStore)
            .environmentObject(addCategoryStore)
        
            .environment(\.addBudgetState, addBudgetStore.state)
            .environment(\.addCategoryState, addCategoryStore.state)
        
            .environment(\.action, handler(action:))
        
            .environment(\.isLoading, addBudgetStore.state.isLoading)
            .environment(\.isLoading, addCategoryStore.state.isLoading)
        
            .task {
                handler(action: .addBudget(.fetch))
                handler(action: .addCategory(.fetch))
            }
    }
    
    func handler(action: MainAction) {
        Task(priority: .high) { @MainActor in
            switch action {
            case let .addBudget(action): try await addBudgetStore.dispatch(action: action)
            case let .addCategory(action): try await addCategoryStore.dispatch(action: action)
            }
        }
    }
}
