//
//  HomeScreen+Variance.swift
//  CashlyKit
//
//  Wave 7 G019: Variance section + shared categoriesView extracted from HomeScreen.swift.
//

import SwiftUI
import CashlyDomain

extension HomeScreen {
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
}
