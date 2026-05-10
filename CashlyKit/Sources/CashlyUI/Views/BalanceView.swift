//
//  BalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 04/09/25.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

struct BalanceView: CashlyView {
    @Environment(\.mainState) var state
    
    @State var isAnimated: Bool = false
    
    @ViewBuilder
    var body: some View {
        if !state.users.isEmpty {
            Group {
                balanceSection
                scoreSection
            }
            .environment(\.isLoading, state.isLoading)
            .onAppear {
                isAnimated = false
                Task {
                    try await Task.sleep(for: .seconds(1))
                    isAnimated = true
                }
            }
        }
    }
    
    var balanceSection: some View {
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
    }
    
    var scoreSection: some View {
        Section {
            let score = state.score
            let enabledScore = score.scores.first(where: { $0.isEnable })
            let enabledScoreValue = enabledScore?.score ?? .zero
            
            CashlyVStack(alignment: .leading, spacing: .medium) {
                CashlyHStack(spacing: .small) {
                    CashlyText(enabledScoreValue.string)
                        .cashly(font: .title, weight: .bold)
                    CashlyText("/  1000")
                        .cashly(font: .footnote)
                        .cashly(color: .textSecondary)
                        .cashlyPadding(.bottom, .negative(.small))
                    CashlySpacer()
                    
                    CashlyText(enabledScore?.title.uppercased())
                        .cashly(font: .caption2, weight: .bold)
                        .cashly(color: .color(enabledScore?.color))
                        .cashlyPadding()
                        .cashlyPadding(.horizontal, .extraSmall)
                        .cashly(glass: .clear.tint(enabledScore?.color.opacity(0.2)).interactive(), in: .capsule)
                }
                
                CashlyHStack(spacing: .small) {
                    ForEach(score.scores) { score in
                        ProgressView(value: score == enabledScore ? score.progress : 1.0, total: 1)
                            .cashly(tint: .color(enabledScoreValue.double > score.max || score == enabledScore ? enabledScore?.color : .clear))
                    }
                }
                
                CashlyText(enabledScore?.summary)
                    .cashly(font: .callout)
            }
            .cashlyPadding()
        } header: {
            CashlyText(CashlyL10n.string("Score"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    func variationView(variation: Double) -> some View {
        CashlyText(variation.variationMessage.uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .color(variation.variationColor))
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(variation.variationColor.opacity(0.2)).interactive(), in: .capsule)
    }
    
    func amountView(variationColor: Color) -> some View {
        CashlyVStack(spacing: .zero) {
            let transactionsAmount = state.transactionsAmount
            
            CashlyText(transactionsAmount.currency())
                    .cashly(font: .largeTitle, weight: .black)
                    .cashly(color: .text)
                    .contentTransition(.numericText(value: transactionsAmount))
        }
    }
    
    @ViewBuilder
    func warningCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
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
                            .animation(.linear.speed(0.5).repeatCount(isAnimated ? .max : .zero, autoreverses: true), value: isAnimated)
                    }
                }
            }
            .minimumScaleFactor(0.3)
            .cashly(alignment: .center)
        }
    }
    
    static var mock: some View {
        BalanceView()
    }
}

#if DEBUG
#Preview {
    CashlyList {
        BalanceView
            .cashlyPreview()
    }
}
#endif
