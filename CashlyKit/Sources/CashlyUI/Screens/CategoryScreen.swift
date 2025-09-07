//
//  CategoryScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct CategoryScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            BalanceView()
            categoriesWithoutBudgetsSection
            categoriesSection
        }
        .lineLimit(2)
        .cashly(font: .callout)
        .environment(\.isLoading, state.isLoading)
        .navigationTitle("Categories")
    }
    
    var categoriesSection: some View {
        Section {
            ForEach(state.categories, id: \.id) {
                categoryItemView(category: $0)
            }
        } header: {
            CashlyText("Budgets")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    @ViewBuilder
    var categoriesWithoutBudgetsSection: some View {
        let categories = state.categories
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
        CashlyHorizontalList {
            CashlyHStack(alignment: .center) {
                ForEach(categories) {
                    categoryIcon(category: $0, isAnimated: true)
                        .cashlyPadding()
                }
            }
            .cashlyPadding(.horizontal, .medium)
        }
        .cashlyPadding(.horizontal, .negative(.medium))
    }
    
    func categoryItemView(category: CashlyDomain.Category) -> some View {
        CashlyHStack(spacing: .zero) {
            categoryIcon(category: category)
                .cashlyPadding(.trailing, .medium)
            
            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyHStack {
                    CashlyText(category.name)
                    CategoryVariationView(category: category)
                        .scaleEffect(0.8)
                    CashlySpacer()
                }
                .cashly(font: .callout, weight: .semibold)
                
                CashlyText(state.budget(for: category)?.summary)
                    .cashly(color: .textSecondary)
            }
            .cashlyPadding(.trailing, .small)
            
            CashlySpacer()
            
            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                let budgetAmount = state.budgetsAmount(for: category)
                let transactionsAmount = state.transactionsAmount(for: category)
            
                CashlyText(budgetAmount.currency())
                    .cashly(font: .callout, weight: .semibold)
                CashlyText(transactionsAmount.currency())
                    .cashly(font: .callout, weight: .semibold)
                    .cashly(color: .textSecondary)
            }
            .cashly(alignment: .trailing)
        }
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
    
    public static var mock: some View {
        CategoryScreen()
    }
}

#Preview {
    NavigationView {
        CategoryScreen
            .cashlyPreview()
    }
}
