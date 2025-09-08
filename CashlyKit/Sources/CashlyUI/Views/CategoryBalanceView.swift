//
//  CategoryBalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct CategoryBalanceView: CashlyView {
    @Environment(\.theme) var theme
    @Environment(\.mainState) var state
    
    @State var isAnimated: Bool = false
    
    var body: some View {
        Section {
            CashlyVStack(spacing: .medium) {
                categoriesAmountView
                amountView
                biggestCategoriesView(categories: state.biggestCategories)
            }
            .cashly(alignment: .center)
            .frame(maxWidth: .infinity)
            .cashlyPadding()
        }
        .environment(\.isLoading, state.isLoading)
        .task {
            Task {
                try await Task.sleep(for: .seconds(1))
                isAnimated = true
            }
        }
    }
    
    var categoriesAmountView: some View {
        CashlyText("\(state.categories.count) categories".uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .primary)
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(theme.color.primary.opacity(0.2)), in: .capsule)
    }
    
    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.budgetsAmount.currency())
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
                .contentTransition(.numericText(value: state.transactionsAmount))
        }
    }
    
    @ViewBuilder
    func biggestCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
            CashlyVStack(spacing: .medium) {
                CashlyText("\(categories.count) biggest budget categories".uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                
                GlassEffectContainer {
                    CashlyHStack(spacing: .zero) {
                        ForEach(categories.enumerated(), id: \.offset) { index, category in
                            let isEven = index.isEven
                            let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                            CashlySymbol(category.icon)
                                .cashly(font: .system(size: 18))
                                .cashly(color: .hex(category.color))
                                .frame(width: 45, height: 45)
                                .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                                    CashlyText((index + 1).string)
                                        .cashly(font: .caption, weight: .bold)
                                        .cashly(color: .hex(category.color))
                                        .cashlyPadding()
                                        .cashly(background: .background)
                                        .cashly(clip: .circle)
                                        .cashlyPadding(.negative(.small))
                                }
                                .cashly(glass: .clear.tint(Color(hex: category.color).opacity(0.2)).interactive(), in: .circle)
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
        CategoryBalanceView()
    }
}

#Preview {
    CashlyList {
        CategoryBalanceView
            .cashlyPreview()
    }
}
