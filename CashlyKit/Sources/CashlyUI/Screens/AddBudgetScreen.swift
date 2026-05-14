//
//  AddBudgetScreen.swift
//  CashlyKit
//
//  Shell + state + handlers for the add/edit-budget flow. Sections
//  live in AddBudgetScreen+Sections, subviews in +Subviews, toolbar
//  items in +Toolbar.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct AddBudgetScreen: CashlyView {
    @Environment(CashlyStore<AddBudgetState, AddBudgetAction>.self) var store

    @Environment(\.addBudgetState) var state
    @Environment(\.mainState) var mainState
    @Environment(\.action) var action
    @Environment(\.router) var router
    @Environment(\.user) var user

    @State var predictionInput: CashlyPredictionInput = .empty
    @State var predictionResult: CashlyPredictionResult = .empty

    var initialState: AddBudgetState?

    public init(initialState: AddBudgetState? = nil) {
        self.initialState = initialState
    }

    public var body: some View {
        Form {
            amountSection
            summarySection
            categoriesSection
            dateSection
            rolloverSection
        }
        .toolbar {
            ToolbarItemGroup {
                usageItem
                quickFillItem
                removeButton
            }

            ToolbarItem { saveButton }
        }
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: state.yearMonth) { action(.addBudget(.fetch)) }
        .onChange(of: state.category) { action(.addBudget(.fetch)) }
        .onChange(of: predictionResult) { handlerPrediction() }
        .task { await handlerInitialState() }
        .cashlyIntelligence(
            model: .budgetValue,
            input: $predictionInput,
            result: $predictionResult
        )
        .cashlyDismiss(isSaved: state.isSaved)
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .onDisappear { store.cancelEffects() }
        .environment(\.isLoading, state.isLoading)
    }

    func handlerPrediction() {
        switch predictionResult {
        case .tabularRegression(let value):
            store.cashlyMutate(\.amount, value)
        default:
            break
        }
    }

    func handlerInitialState() async {
        if let initialState {
            store.cashlyReplace(initialState)
        }
        await Task.yield()
        action(.addBudget(.fetch))
    }

    public static var mock: some View {
        AddBudgetScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddBudgetScreen
            .cashlyPreview()
    }
}
#endif
