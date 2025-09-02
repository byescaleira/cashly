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
        
            .environment(\.isLoading, addBudgetStore.state.isLoading)
            .environment(\.isLoading, addCategoryStore.state.isLoading)
    }
}
