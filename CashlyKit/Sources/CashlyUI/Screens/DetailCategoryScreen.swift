//
//  DetailCategoryScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 15/09/25.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct DetailCategoryScreen: CashlyView {
    @Environment(CashlyStore<MainState, MainAction>.self) var store
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    let category: CashlyDomain.Category
    
    public init(category: CashlyDomain.Category) {
        self.category = category
    }
    
    public var body: some View {
        CashlyList {
            headerSection
            descriptionSection
            budgetsSection
        }
        .navigationTitle(category.name.capitalized)
        .environment(\.isLoading, state.isLoading)
        .onAppear { action(.main(.fetch)) }
        .refreshable { action(.main(.fetch)) }
    }
    
    var headerSection: some View {
        Section {
            CashlyText(state.budget(for: category)?.summary)
                .frame(maxWidth: .infinity)
                .cashly(alignment: .center)
                .cashlyPadding()
        } header: {
            CashlyVStack(spacing: .medium) {
                iconView
                amountView
                CategoryVariationView(category: category)
                    .scaleEffect(1.2)
            }
            .cashly(alignment: .center)
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .medium)
        }
    }
    
    var descriptionSection: some View {
        Section {
            
        }
    }
    
    var iconView: some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 30))
            .cashly(color: .hex(category.color))
            .frame(width: 70, height: 70)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(Color(hex: category.color), lineWidth: 5)
                    .frame(width: 80, height: 80)
            }
            .cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
    }
    
    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.budgetsAmount(for: category).currency())
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
            
            CashlyText(state.transactionsAmount(for: category).currency())
                .cashly(font: .title2, weight: .bold)
                .cashly(color: .textSecondary)
        }
    }
    
    @ViewBuilder
    var budgetsSection: some View {
        let budgets = state.budgets(for: category)
        if !budgets.isEmpty {
            Section {
                ForEach(budgets) { budget in
                    CashlyButton {
                        router.route(to: .addBudget(state: .edit(id: budget.id)))
                    } label: {
                        budgetItemView(budget: budget)
                    }
                    .cashly(color: .text)
                }
            } header: {
                CashlyText(CashlyL10n.string("Budgets"))
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
        }
    }
    
    func budgetItemView(budget: Budget) -> some View {
        CashlyHStack(spacing: .medium) {
            let transactionAmount = state.transactionsAmount(for: budget)
            let budgetAmount = budget.amount
            let variation = transactionAmount / (budgetAmount.isZero ? 1 : budgetAmount)
            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(budget.date.string.date(with: .cashly(.yearMonth))?.string(with: .cashly(.status)))
                    .cashly(font: .callout, weight: .semibold)
                CashlyText(variation.percentage)
            }
            
            CashlySpacer()
            
            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                CashlyText(budgetAmount.currency())
                    .cashly(font: .callout, weight: .semibold)
                CashlyText(transactionAmount.currency())
            }
            
            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .cashly(font: .callout)
    }
    
    #if DEBUG
    public static var mock: some View {
        DetailCategoryScreen(category: .mock)
    }
    #endif
}

#if DEBUG
#Preview {
    NavigationView {
        DetailCategoryScreen
            .cashlyPreview()
    }
}
#endif

