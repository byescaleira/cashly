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
    
    var body: some View {
        Section {
            CashlyVStack(spacing: .medium) {
                let variation = state.variation
                variationView(variation: variation)
                let warningCategories = state.warningCategories
                amountView(categories: warningCategories, variationColor: variation.variationColor)
                if warningCategories.isEmpty {
                    transactionsAmountDescription(categories: warningCategories)
                }
                warningCategoriesView(categories: warningCategories)
            }
            .cashly(alignment: .center)
            .frame(maxWidth: .infinity)
            .cashlyPadding()
        } header: {
            CashlyText("Balance")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
        .environment(\.isLoading, state.isLoading)
        .task {
            Task {
                try await Task.sleep(for: .seconds(1))
                isAnimated = true
            }
        }
    }
    
    func transactionsAmountDescription(categories: [CashlyDomain.Category]) -> some View {
        CashlyText((categories.isEmpty ? "You’ve made \(state.transactions.count) transactions, totaling the amount shown above." : "\(state.transactions.count) transactions").uppercased())
            .cashly(font: .caption, weight: .semibold)
            .cashly(color: .textSecondary)
    }
    
    func variationView(variation: Double) -> some View {
        GlassEffectContainer {
            CashlyHStack(spacing: .negative(.extraSmall)) {
                CashlyText(variation.variationMessage.uppercased())
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .color(variation.variationColor))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(variation.variationColor.opacity(0.2)), in: .capsule)
                CashlyText(variation.percentage)
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .color(variation.variationColor))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(variation.variationColor.opacity(0.2)), in: .capsule)
            }
        }
    }
    
    func amountView(categories: [CashlyDomain.Category], variationColor: Color) -> some View {
        CashlyVStack(spacing: .zero) {
            let transactionsAmount = state.transactionsAmount
            let remainingAmount = state.remainingAmount
            
            CashlyVStack(spacing: .zero) {
                if !categories.isEmpty {
                    transactionsAmountDescription(categories: categories)
                }
                
                CashlyText(transactionsAmount.currency())
                    .cashly(font: .largeTitle, weight: .black)
                    .cashly(color: .text)
                    .contentTransition(.numericText(value: transactionsAmount))
            }
            
            CashlyVStack(spacing: .zero) {
                CashlyText(remainingAmount.currency())
                    .cashly(font: .title, weight: .bold)
                    .cashly(color: .color(variationColor))
                    .contentTransition(.numericText(value: remainingAmount))
                
                CashlyText("Remaining Budget".uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
            }
        }
    }
    
    @ViewBuilder
    func warningCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
            CashlyVStack(spacing: .medium) {
                CashlyText("Top \(categories.count) categories where you need to be cautious.".uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                    .cashlyPadding(.horizontal)
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
