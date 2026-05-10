//
//  HomeScreen+OtherSections.swift
//  CashlyKit
//
//  Wave 7 G019: Available/BiggestTransaction/SpendingForecast sections
//  extracted from HomeScreen.swift.
//

import SwiftUI
import CashlyResource
import CashlyDomain

extension HomeScreen {
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
                            CashlyText(CashlyL10n.string("Selected category"))
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

                    CashlyText(CashlyL10n.string("Available"))
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
                    CashlyText(CashlyL10n.string("Top Spending"))
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
                       CashlyText(CashlyL10n.string("Smart estimates of your monthly expenses, generated by AI based on your financial history and spending patterns."))
                           .cashly(font: .callout)
                           .cashly(color: .textSecondary)

                       CashlyText(state.predictedTransactionsAmount.currency())
                           .cashly(font: .largeTitle, weight: .black)
                           .cashly(color: .text)
                   }
                   .frame(maxWidth: .infinity, alignment: .center)
                   .cashly(alignment: .center)
               } header: {
                   CashlyText(CashlyL10n.string("Spending Forecast"))
                       .cashly(font: .title3, weight: .semibold)
                       .cashly(color: .text)
               }
           }
    }
}
