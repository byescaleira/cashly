//
//  HomeScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct HomeScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            BalanceView()
            availableSection
            varianceSection
            biggestTransactionSection
            tagsSection
            spendingForecastSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { FilterItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .navigationTitle((state.user?.selfFirstName ?? "") + "Home")
    }
    
    @State var selectedTag: Tag?
    
    @ViewBuilder
    var tagsSection: some View {
        EmptyTagView()
        
        if !state.tags.isEmpty {
            Section {
                let data: [(String, Double)] = state.tags.map {
                    let amount = state.transactionsAmount(for: $0)
                    return ($0.name.capitalized, amount)
                }
                
                if let selectedTag {
                    let amount = data.first(where: { $0.0 == selectedTag.name })?.1
                    
                    CashlyButton {
                        router.route(to: .addTag(state: .edit(id: selectedTag.id)))
                    } label: {
                        CashlyHStack {
                            CashlyText(selectedTag.name.uppercased())
                                .cashly(font: .caption2, weight: .bold)
                                .cashly(color: .hex(selectedTag.color))
                                .cashlyPadding()
                                .cashlyPadding(.horizontal, .extraSmall)
                                .cashly(glass: .clear.tint(.init(hex: selectedTag.color).opacity(0.2)).interactive(), in: .capsule)
                            
                            CashlySpacer()
                            
                            CashlyText(amount?.currency())
                                .cashly(font: .title3, weight: .bold)
                                .cashly(color: .text)
                                .contentTransition(.numericText())
                            
                            CashlySymbol("chevron.forward")
                                .cashly(color: .disabled)
                        }
                        .animation(.bouncy, value: amount)
                    }
                    .cashly(tint: .text)
                }
                
                CashlyChart(
                    type: .line,
                    startItemsAmount: 4.5,
                    data: data
                )
                
                CashlyButton {
                    router.route(to: .addTag(state: .new()))
                } label: {
                    CashlyHStack {
                        CashlyText("Add new tag")
                        CashlySpacer()
                        CashlySymbol("chevron.forward")
                            .cashly(color: .disabled)
                    }
                }
                .cashly(tint: .text)
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    CashlyText("Tags")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)
                    
                    tagsView
                }
                .frame(maxWidth: .infinity)
                .cashly(alignment: .leading)
            }
        }
    }
    
    var tagsView: some View {
        CashlyVStack(alignment: .leading, spacing: .small) {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.tags) { tag in
                        CashlyButton {
                            selectedTag = tag
                        } label: {
                            CashlySymbol(tag.icon)
                                .cashly(font: .system(size: 20))
                                .cashly(color: selectedTag == tag ? .hex(tag.color) : .color(.secondary))
                                .frame(width: 45, height: 45)
                                .cashly(background: .color((selectedTag == tag ? Color(hex: tag.color) : .secondary).opacity(0.2)))
                                .cashly(clip: .circle)
                                .overlay {
                                    Circle()
                                        .stroke(selectedTag == tag ? Color(hex: tag.color) : .secondary, lineWidth: 3)
                                        .frame(width: 50, height: 50)
                                }
                                .opacity(selectedTag == tag ? 1 : 0.3)
                                .cashly(if: tag == selectedTag) {
                                    $0.cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
                                }
                        }
                        .id(tag)
                        .cashlyPadding()
                    }
                }
                .onChange(of: selectedTag) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(selectedTag, anchor: .center)
                        }
                    }
                }
                .animation(.bouncy, value: selectedTag)
                .padding(.horizontal, 40)
            }
            .onAppear { selectedTag = selectedTag == nil ? state.tags.first : selectedTag }
            .padding(.horizontal, -40)
        }
    }
    
    @State var selectedCompareCategory: CashlyDomain.Category?
    
    @ViewBuilder
    var varianceSection: some View {
        if !state.categories.isEmpty,
           !state.budgets.isEmpty {
            Section {
                let data = state.categories.map { category in
                    let budgets = state.budgets(for: category)
                    let categoryName = category.name.capitalized
                    let budgetAmount = budgets.reduce(.zero) { $0 + $1.amount }
                    let transactionsAmount = state.transactionsAmount(for: category)
                    return (categoryName, budgetAmount, transactionsAmount)
                }
                
                let selectedData = data.first(where: { $0.0.lowercased() == selectedCompareCategory?.name.lowercased() })
                let budgetAmount = selectedData?.1 ?? .zero
                let transactionsAmount = selectedData?.2 ?? .zero
                let variation = transactionsAmount / (budgetAmount == .zero ? 1 : budgetAmount)
                let percentage = variation > 1 ? 1 - variation : variation
                
                CashlyHStack(spacing: .extraSmall) {
                    CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                        CashlyText(budgetAmount.currency())
                            .cashly(font: .title3, weight: .bold)
                            .cashly(color: .text)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: budgetAmount)
                        
                        CashlyText("Budget")
                            .cashly(font: .callout, weight: .semibold)
                            .cashly(color: .info)
                    }
                    .cashly(alignment: .leading)
                    
                    CashlySpacer()
                    
                    CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                        CashlyText(transactionsAmount.currency())
                            .cashly(font: .title3, weight: .bold)
                            .cashly(color: .text)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: transactionsAmount)
                        
                        CashlyHStack(spacing: .small) {
                            CashlyText(percentage.percentage)
                                .cashly(font: .footnote, weight: .bold)
                                .cashly(color: .textSecondary)
                                .contentTransition(.numericText())
                                .animation(.bouncy, value: percentage)
                            
                            CashlyText("Expense")
                                .cashly(font: .callout, weight: .semibold)
                                .cashly(color: .primary)
                        }
                    }
                    .cashly(alignment: .trailing)
                }
                
                CashlyCompareChart(type: .bar, data: data)
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    CashlyText("Variance")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)
                    
                    categoriesView(selected: $selectedCompareCategory)
                }
                .frame(maxWidth: .infinity)
                .cashly(alignment: .leading)
            }
        }
    }
    
    func categoriesView(selected: Binding<CashlyDomain.Category?>) -> some View {
        CashlyVStack(alignment: .leading, spacing: .small) {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        CashlyButton {
                            selected.wrappedValue = category
                        } label: {
                            CashlySymbol(category.icon)
                                .cashly(font: .system(size: 20))
                                .cashly(color: selected.wrappedValue == category ? .hex(category.color) : .color(.secondary))
                                .frame(width: 45, height: 45)
                                .cashly(background: .color((selected.wrappedValue == category ? Color(hex: category.color) : .secondary).opacity(0.2)))
                                .cashly(clip: .circle)
                                .overlay {
                                    Circle()
                                        .stroke(selected.wrappedValue == category ? Color(hex: category.color) : .secondary, lineWidth: 3)
                                        .frame(width: 50, height: 50)
                                }
                                .opacity(selected.wrappedValue == category ? 1 : 0.3)
                                .cashly(if: category == selected.wrappedValue) {
                                    $0.cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
                                }
                        }
                        .id(category)
                        .cashlyPadding()
                    }
                }
                .onChange(of: selected.wrappedValue) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(selected.wrappedValue, anchor: .center)
                        }
                    }
                }
                .animation(.bouncy, value: selected.wrappedValue)
                .padding(.horizontal, 40)
            }
            .onAppear { selected.wrappedValue = selected.wrappedValue == nil ? state.categories.first : selected.wrappedValue }
            .padding(.horizontal, -40)
        }
    }
    
    @State var selectedAvailableCategory: CashlyDomain.Category?
    
    @ViewBuilder
    var availableSection: some View {
        if !state.budgets.isEmpty {
            Section {
                if let selectedAvailableCategory {
                    let budgetsAmount = state.budgetsAmount(for: selectedAvailableCategory)
                    let transactionsAmount = state.transactionsAmount(for: selectedAvailableCategory)
                    let availableCategory = budgetsAmount - transactionsAmount
                    let conventionalVariation = transactionsAmount / (budgetsAmount.isZero ? 1 : budgetsAmount)
                    let variation = 1 - conventionalVariation
                    Menu {
                        Picker(selection: $selectedAvailableCategory) {
                            ForEach(state.categories) {
                                CashlyText($0.name)
                                    .tag($0)
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        CashlyHStack(spacing: .medium) {
                            CashlyText("Selected category")
                                .cashly(font: .body)
                                .cashly(color: .text)
                            
                            CashlySpacer()
                            
                            CashlyHStack {
                                CashlyText(selectedAvailableCategory.name.capitalized)
                                    .cashly(font: .body, weight: .semibold)
                                
                                CashlySymbol("chevron.up.chevron.down")
                                    .cashly(font: .footnote, weight: .semibold)
                            }
                            .cashly(color: .primary)
                        }
                    }
                    
                    CashlyHStack(spacing: .small) {
                        CashlyText(availableCategory.currency())
                            .cashly(font: .title3, weight: .bold)
                        CashlyText("/  \(budgetsAmount.currency() ?? "")")
                            .cashly(font: .footnote)
                            .cashly(color: .textSecondary)
                            .cashlyPadding(.bottom, .negative(.extraSmall))
                        
                        CashlySpacer()
                        
                        CashlyText(variation.percentage)
                            .cashly(font: .caption2, weight: .bold)
                            .cashly(color: .color(conventionalVariation.variationColor))
                            .cashlyPadding()
                            .cashlyPadding(.horizontal, .extraSmall)
                            .cashly(glass: .clear.tint(conventionalVariation.variationColor.opacity(0.2)).interactive(), in: .capsule)
                    }
                }
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    let budgetsAmount = state.budgetsAmount
                    let transactionsAmount = state.transactionsAmount
                    let available = budgetsAmount - transactionsAmount
                    
                    CashlyText("Available")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CashlyVStack(spacing: .extraSmall) {
                        CashlyText(available.currency())
                            .cashly(font: .largeTitle, weight: .black)
                            .cashly(color: .text)
                            .cashly(alignment: .center)
                        
                        CashlyText(budgetsAmount.currency())
                            .cashly(font: .title3, weight: .semibold)
                            .cashly(color: .textSecondary)
                            .cashly(alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .cashlyPadding(.vertical, .large)
                }
                .onAppear {
                    selectedAvailableCategory = selectedAvailableCategory == nil ?
                    state.categories.first : selectedAvailableCategory
                }
            }
        }
    }
    
    @State var selectedBiggestTransactionIndex: Int = .zero
    
    @ViewBuilder
    var biggestTransactionSection: some View {
        let transactions = state.biggestTransactions
        if !transactions.isEmpty {
            Section {
                TabView(selection: $selectedBiggestTransactionIndex) {
                    ForEach(transactions.enumerated(), id: \.offset) { index, transaction in
                        CashlyVStack(spacing: .small) {
                            let category = transaction.budget.category
                            CashlySpacer()
                            CashlyText(category.name.uppercased())
                                .cashly(font: .caption2, weight: .bold)
                                .cashly(color: .hex(category.color))
                                .cashlyPadding()
                                .cashlyPadding(.horizontal, .extraSmall)
                                .cashly(glass: .clear.tint(.init(hex: category.color).opacity(0.2)), in: .capsule)
                            
                            CashlyText(transaction.amount.currency())
                                .cashly(font: .title, weight: .bold)
                                .cashly(color: .text)
                        
                            CashlyText(transaction.summary)
                                .cashly(color: .textSecondary)
                            CashlySpacer()
                        }
                        .cashly(alignment: .center)
                        .padding(.horizontal, 50)
                        .id(index)
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, -20)
                .animation(.bouncy, value: selectedBiggestTransactionIndex)
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            } header: {
                CashlyHStack {
                    CashlyText("Top Spending")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)
                    
                    CashlySpacer()
                    
                    CashlyHStack(spacing: .extraSmall) {
                        ForEach(transactions.enumerated(), id: \.offset) { index, _ in
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundStyle(
                                    index == selectedBiggestTransactionIndex ?
                                    Color.accentColor : .primary.opacity(0.1)
                                )
                        }
                    }
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(.secondary.opacity(0.2)), in: .capsule)
                }
            } footer: {
                
            }
        }
    }
    
    @ViewBuilder
    var spendingForecastSection: some View {
        if let user = state.user,
           CashlyIntelligence.allCases.allSatisfy ({ $0.model(for: user)?.createDate != nil }) {
               Section {
                   CashlyVStack(spacing: .medium) {
                       CashlyText("Smart estimates of your monthly expenses, generated by AI based on your financial history and spending patterns.")
                           .cashly(font: .callout)
                           .cashly(color: .textSecondary)
                       
                       CashlyText(state.predictedTransactionsAmount.currency())
                           .cashly(font: .largeTitle, weight: .black)
                           .cashly(color: .text)
                   }
                   .frame(maxWidth: .infinity, alignment: .center)
                   .cashly(alignment: .center)
               } header: {
                   CashlyText("Spending Forecast")
                       .cashly(font: .title3, weight: .semibold)
                       .cashly(color: .text)
               }
           }
    }
    
    public static var mock: some View {
        HomeScreen()
    }
}

#Preview {
    NavigationView {
        HomeScreen
            .cashlyPreview()
    }
}
