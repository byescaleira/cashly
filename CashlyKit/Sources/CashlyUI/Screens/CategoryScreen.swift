//
//  CategoryScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct CategoryScreen: CashlyView {
    @Environment(CashlyStore<MainReducer, MainMiddleware>.self) var store
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            CategoryBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            categoriesWithoutBudgetsSection
            categoriesSection
        }
        .lineLimit(2)
        .cashly(font: .callout)
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { FilterItemView() }
            ToolbarSpacer(.fixed)
            ToolbarItem { addButton }
        }
        .environment(\.isLoading, state.isLoading)
        .onAppear { action(.main(.fetch)) }
        .refreshable { action(.main(.fetch)) }
        .navigationTitle("Categories")
    }
    
    @ViewBuilder
    var categoriesSection: some View {
        let categories = state.categoriesWithBudgets
        if !categories.isEmpty {
            Section {
                ForEach(categories, id: \.id) { category in
                    CashlyButton {
                        router.route(to: .detailCategory(category: category))
                    } label: {
                        categoryItemView(category: category)
                    }
                    .cashly(tint: .text)
                    .cashlyEdit { router.route(to: .addCategory(state: .edit(id: category.id))) }
                }
            } header: {
                CashlyText("Budgets")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }
    
    @ViewBuilder
    var categoriesWithoutBudgetsSection: some View {
        let categories = state.categoriesWithoutBudgets
        if !categories.isEmpty, state.filter.isFilteringByDate {
            Section {
                CashlyVStack(alignment: .leading) {
                    CashlyText("This category doesn’t have a budget yet. Add one below to help track your spending.")
                    categoriesWithoutBudgetsView(categories: categories)
                }
                .frame(maxWidth: .infinity)
            } header: {
                CashlyText("Want more control?")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }
    
    func categoriesWithoutBudgetsView(categories: [CashlyDomain.Category]) -> some View {
        CashlyHorizontalList { _ in
            CashlyHStack(alignment: .center) {
                ForEach(categories) { category in
                    CashlyButton {
                        router.route(to: .addBudget(state: .new(category: category, date: state.filter.startDate)))
                    } label: {
                        categoryIcon(category: category, isAnimated: true)
                    }
                    .cashlyPadding()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyHStack(spacing: .medium) {
            categoryIcon(category: category)
            
            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyHStack {
                    CashlyText(category.name)
                    CashlySpacer()
                }
                .cashly(font: .callout, weight: .semibold)
                
                CashlyText(state.budget(for: category)?.summary)
                    .cashly(color: .textSecondary)
            }
            
            CashlySpacer()
            
            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                let budgetAmount = state.budgetsAmount(for: category)
                let transactionsAmount = state.transactionsAmount(for: category)
                
                CategoryVariationView(category: category)
                    .scaleEffect(0.7)
                    .padding(.trailing, -6)
            
                if budgetAmount > .zero {
                    CashlyText(budgetAmount.currency())
                        .cashly(font: .callout, weight: .semibold)
                }
                
                if transactionsAmount > .zero {
                    CashlyText(transactionsAmount.currency())
                        .cashly(font: .callout, weight: .semibold)
                        .cashly(color: .textSecondary)
                }
            }
            .cashly(alignment: .trailing)
            
            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .cashlyEdit { router.route(to: .addCategory(state: .edit(id: category.id))) }
    }
    
    func categoryIcon(category: CashlyDomain.Category, isAnimated: Bool = false) -> some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 18))
            .cashly(color: .hex(category.color))
            .frame(width: 40, height: 40)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                if isAnimated {
                    Circle()
                        .stroke(Color(hex: category.color), lineWidth: 2)
                        .frame(width: 45, height: 45)
                }
            }
            .cashly(if: isAnimated) {
                $0.cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
            }
    }
    
    @ViewBuilder
    var addButton: some View {
        if !state.users.isEmpty {
            CashlyButton {
                router.route(to: .addCategory(state: .new()))
            } label: {
                CashlySymbol("plus")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }
    
    public static var mock: some View {
        CategoryScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        CategoryScreen
            .cashlyPreview()
    }
}
#endif
