//
//  AddBudgetScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyPresentation

public struct AddBudgetScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddBudgetReducer, AddBudgetMiddleware>
    
    @Environment(\.addBudgetState) var state
    @Environment(\.action) var action
    
    public init() {}
    
    public var body: some View {
        Form {
            amountSection
            summarySection
            categoriesSection
            dateSection
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                CashlyHStack(spacing: .medium) {
                    saveButton
                    removeButton
                }
                .cashlyPadding()
                .cashlyPadding(.horizontal)
            }
        }
    }
    
    var amountSection: some View {
        Section {} header: {
            CashlyCurrencyTextField(amount: $store.state.amount)
                .frame(maxWidth: .infinity)
                .cashly(alignment: .center)
                .cashly(font: .system(size: 40), weight: .black)
                .cashlyPadding(.top, .medium)
                .cashly(tint: .color(.clear))
        }
    }
    
    var summarySection: some View {
        Section {
            TextField(
                "Provide a summary of your budget",
                text: $store.state.summary,
                axis: .vertical
            )
        } header: {
            CashlyText("Summary")
                .headerProminence(.increased)
        }
    }
    
    var categoriesSection: some View {
        Section {
            categoriesView
            emptyCategoriesView
        } header: {
            CashlyText("Categories")
                .headerProminence(.increased)
        }
    }
    
    @ViewBuilder
    var categoriesView: some View {
        if !state.categories.isEmpty {
            CashlyHorizontalList {
                CashlyHStack(spacing: .medium) {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var emptyCategoriesView: some View {
        if state.categories.isEmpty {
            CashlyCardView(
                image: .illustrationEmpty,
                title: "No Categories Found",
                subtitle: "You don’t have any categories yet. Start by creating one to organize your expenses.",
                buttonTitle: "Create Category"
            ) {
                
            }
            .cashlyPadding(.medium)
        }
    }
    
    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyButton {
            store.state.category = category
        } label: {
            CashlySymbol(category.icon)
                .cashly(font: .system(size: 20))
                .cashly(color: .hex(category.color))
                .frame(width: 45, height: 45)
                .cashly(background: .color(Color(hex: category.color).opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    Circle()
                        .stroke(Color(hex: category.color), lineWidth: 3)
                        .frame(width: 50, height: 50)
                }
        }
        .buttonStyle(.plain)
    }
    
    var dateSection: some View {
        Section {
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
                .headerProminence(.increased)
        }
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addCategory(.save))
        } label: {
            CashlyText(state.isNew ? "Create" : "Save")
                .cashly(font: .headline, weight: .semibold)
        }
        .disabled(!state.canSave)
        .cashly(tint: .primary)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            Divider()
            CashlyButton {
                action(.addCategory(.remove))
            } label: {
                CashlySymbol("trash")
                    .cashly(font: .headline, weight: .bold)
            }
            .cashly(tint: .primary)
        }
    }
    
    public static var mock: some View {
        AddBudgetScreen()
    }
}

#Preview {
    AddBudgetScreen
        .mock
        .cashlyPreview()
}
