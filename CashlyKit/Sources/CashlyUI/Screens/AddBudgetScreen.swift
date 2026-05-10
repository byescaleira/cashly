//
//  AddBudgetScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct AddBudgetScreen: CashlyView {
    @Environment(CashlyStore<AddBudgetReducer, AddBudgetMiddleware>.self) var store
    
    @Environment(\.addBudgetState) var state
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
        }
        .toolbar {
            ToolbarItemGroup {
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
        .environment(\.isLoading, state.isLoading)
    }
    
    func handlerPrediction() {
        switch predictionResult {
        case .tabularRegression(let value):
            store.state.amount = value
        default:
            break
        }
    }
    
    func handlerInitialState() async {
        if let initialState {
            store.state = initialState
        }
        try? await Task.sleep(for: .seconds(0.5))
        action(.addBudget(.fetch))
    }
    
    var amountSection: some View {
        @Bindable var store = store
        return Section {} header: {
            CashlyVStack(spacing: .zero) {
                CashlyText(state.category?.name.uppercased())
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .hex(state.category?.color))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(Color(hex: state.category?.color).opacity(0.2)), in: .capsule)
                
                CashlyCurrencyTextField(amount: $store.state.amount)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .frame(maxWidth: .infinity)
                    .cashly(alignment: .center)
                    .cashly(font: .system(size: 40), weight: .black)
                    .cashlyPadding(.top, .medium)
                    .cashly(tint: .color(.clear))
            }
        }
    }
    
    var summarySection: some View {
        @Bindable var store = store
        return Section {
            TextField(
                "Provide a summary of your budget",
                text: $store.state.summary,
                axis: .vertical
            )
        } header: {
            CashlyText("Summary")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    var categoriesSection: some View {
        Section {
            categoriesView
            EmptyCategoryView()
        } header: {
            CashlyText("Categories")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    @ViewBuilder
    var categoriesView: some View {
        if !state.categories.isEmpty {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                            .id(category)
                    }
                }
                .cashlyPadding(.horizontal, .medium)
                .onChange(of: state.category) {
                    withAnimation(.bouncy) {
                        proxy.scrollTo(state.category, anchor: .center)
                    }
                }
            }
            .cashlyPadding(.horizontal, .negative(.medium))
        }
    }
    
    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyButton {
            store.state.category = category
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(color: state.category == category ? .hex(category.color) : .color(.secondary))
                .frame(width: 45, height: 45)
                .cashly(background: .color((state.category == category ? Color(hex: category.color) : .secondary).opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(state.category == category ? Color(hex: category.color) : .secondary, lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
                .opacity(state.category == category ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .cashlyPadding()
    }
    
    var dateSection: some View {
        @Bindable var store = store
        return Section {
            DatePicker(
                "",
                selection: $store.state.date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .cashlyPadding(.vertical, .negative(.medium))
            .cashly(tint: .primary)
        } header: {
            CashlyText("Date")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addBudget(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addBudget(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }
    
    @ViewBuilder
    var quickFillItem: some View {
        if let user,
           let model = CashlyIntelligence.budgetValue.model(for: user),
           model.createDate != nil {
            CashlyButton {
                predictionInput = .tabularData(
                    .budgetValue(
                        date: state.date.timeIntervalSince1970.yearMonth,
                        category: state.category?.name ?? ""
                    )
                )
            } label: {
                CashlySymbol("bolt.fill")
            }
            .cashly(tint: .color(.yellow))
        }
    }
    
    public static var mock: some View {
        AddBudgetScreen()
    }
}

#Preview {
    NavigationView {
        AddBudgetScreen
            .cashlyPreview()
    }
}
