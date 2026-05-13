//
//  AddTransactionScreen.swift
//  CashlyKit
//
//  //  body + state declarations only. Sections, sub-views,
//  toolbar items and handlers live in AddTransactionScreen+*.swift.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyPresentation

public struct AddTransactionScreen: CashlyView {
    @Environment(CashlyStore<AddTransactionState, AddTransactionAction>.self) var store

    @Environment(\.addTransactionState) var state
    @Environment(\.mainState) var mainState
    @Environment(\.action) var action
    @Environment(\.router) var router
    @Environment(\.user) var user

    @State var selectedUsers: Set<User> = []
    @State var isActivePrediction: Bool = true
    @State var predictionResult: CashlyPredictionResult = .empty
    @State var isDictating: Bool = false
    @State var dictationInterim: String = ""

    @Environment(\.transactionDictation) var transactionDictation
    @Environment(\.speechTranscriber) var speechTranscriber

    var predictionInput: Binding<CashlyPredictionInput> {
        Binding {
            state.summary.isEmpty ? .empty : .text(state.summary)
        } set: { _ in }
    }

    var initialState: AddTransactionState?

    public init(initialState: AddTransactionState? = nil) {
        self.initialState = initialState
    }

    public var body: some View {
        Form {
            kindSection
            amountSection
            summarySection
            categoriesSection
            dateSection
            installmentSection
            selectedParticipantsSection
        }
        .toolbar {
            ToolbarItemGroup {
                dictationItem
                intelligenceItem
                participantsItem
                removeButton
            }

            ToolbarItem { saveButton }
        }
        .task { await handlerInitialState() }
        .onChange(of: selectedUsers) { onChangeSelectedUsers() }
        .onChange(of: state.participants) { updateSplitValue() }
        .onChange(of: state.amount) { updateSplitValue() }
        .onChange(of: predictionResult) { handlerPrediction() }
        .onDisappear {
            selectedUsers = []
            store.cancelEffects()
        }
        .scrollDismissesKeyboard(.immediately)
        .cashlyIntelligence(
            model: .categoryName,
            isActive: isActivePrediction,
            input: predictionInput,
            publishEvery: 1,
            result: $predictionResult
        )
        .cashlyDismiss(isSaved: state.isSaved)
        .cashlyErrorAlert(error: state.error) { store.cashlyMutate(\.error, nil) }
        .environment(\.isLoading, state.isLoading)
    }

    public static var mock: some View {
        AddTransactionScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddTransactionScreen
            .cashlyPreview()
    }
}
#endif
