//
//  BalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct BalanceView: CashlyView {
    @Environment(\.mainState) var state
    
    @State var isAnimated: Bool = false
    
    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
           !state.budgets.isEmpty,
           !state.transactions.isEmpty {
            Section {
                
            } header: {
                CashlyVStack(spacing: .medium) {
                    let variation = state.variation
                    variationView(variation: variation)
                    let warningCategories = state.warningCategories
                    amountView(variationColor: variation.variationColor)
                    warningCategoriesView(categories: warningCategories)
                }
                .cashly(alignment: .center)
                .frame(maxWidth: .infinity)
                .cashlyPadding(.top, .medium)
            }
            .environment(\.isLoading, state.isLoading)
            .task {
                Task {
                    try await Task.sleep(for: .seconds(1))
                    isAnimated = true
                }
            }
        }
    }
    
    func variationView(variation: Double) -> some View {
        CashlyText(variation.variationMessage.uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .color(variation.variationColor))
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(variation.variationColor.opacity(0.2)), in: .capsule)
    }
    
    func amountView(variationColor: Color) -> some View {
        CashlyVStack(spacing: .zero) {
            let transactionsAmount = state.transactionsAmount
            let remainingAmount = state.remainingAmount
            
            CashlyText(transactionsAmount.currency())
                    .cashly(font: .largeTitle, weight: .black)
                    .cashly(color: .text)
                    .contentTransition(.numericText(value: transactionsAmount))
            
            CashlyVStack(spacing: .zero) {
                CashlyText(remainingAmount.currency())
                    .cashly(font: .title2, weight: .black)
                    .cashly(color: .color(variationColor))
                    .contentTransition(.numericText(value: remainingAmount))
                
                CashlyText("Remaining Budget".uppercased())
                    .cashly(font: .caption2, weight: .semibold)
                    .cashly(color: .textSecondary)
            }
        }
    }
    
    @ViewBuilder
    func warningCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
            CashlyVStack(spacing: .small) {
                GlassEffectContainer {
                    CashlyHStack(spacing: .zero) {
                        ForEach(categories.enumerated(), id: \.offset) { index, category in
                            let variation = state.categoryVariation(category: category)
                            let isEven = index.isEven
                            let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                            CashlySymbol(category.icon)
                                .cashly(font: .system(size: 18))
                                .cashly(color: .color(variation.variationColor))
                                .frame(width: 45, height: 45)
                                .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                                    CashlyText((index + 1).string)
                                        .cashly(font: .caption, weight: .bold)
                                        .cashly(color: .color(variation.variationColor))
                                        .cashlyPadding()
                                        .cashly(background: .background)
                                        .cashly(clip: .circle)
                                        .cashlyPadding(.negative(.small))
                                }
                                .cashly(glass: .clear.tint(variation.variationColor.opacity(0.2)).interactive(), in: .circle)
                                .offset(y: point)
                                .animation(.linear.speed(0.5).repeatForever(autoreverses: true), value: isAnimated)
                        }
                    }
                }
                .minimumScaleFactor(0.3)
                
                CashlyText("Top \(categories.count) categories where\nyou need to be cautious.".uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                    .cashlyPadding(.horizontal)
            }
            .cashly(alignment: .center)
        }
    }
    
    static var mock: some View {
        BalanceView()
    }
}

#Preview {
    CashlyList {
        BalanceView
            .cashlyPreview()
    }
}
