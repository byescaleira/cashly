import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct BalanceView: View {
    @Environment(MainViewModel.self) var state

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var isAnimated: Bool = false

    @ViewBuilder
    var body: some View {
        if !state.users.isEmpty {
            Group {
                balanceSection
                scoreSection
            }
            .environment(\.isLoading, state.isLoading)
            .task(id: reduceMotion) {
                isAnimated = false
                guard !reduceMotion else { return }
                do {
                    try await Task.sleep(for: .seconds(1))
                    try Task.checkCancellation()
                    isAnimated = true
                } catch {}
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
                    CashlyText(String(enabledScoreValue))
                        .cashly(font: .title, weight: .bold)
                    CashlyText("/  1000")
                        .cashly(font: .footnote)
                        .cashly(color: .textSecondary)
                        .cashlyPadding(.bottom, .negative(.small))
                    Spacer()

                    CashlyText(enabledScore?.title.uppercased())
                        .cashly(font: .caption2, weight: .bold)
                        .cashly(color: .color(enabledScore?.color.color ?? .secondary))
                        .cashlyPadding()
                        .cashlyPadding(.horizontal, .extraSmall)
                        .cashlyContentSurface(
                            tint: enabledScore?.color.color.opacity(0.2), in: .capsule)
                }

                CashlyHStack(spacing: .small) {
                    ForEach(score.scores) { score in
                        ProgressView(value: score == enabledScore ? score.progress : 1.0, total: 1)
                            .cashly(
                                tint: .color(
                                    Double(enabledScoreValue) > score.max || score == enabledScore
                                        ? (enabledScore?.color.color ?? .secondary) : .clear))
                    }
                }

                CashlyText(enabledScore?.summary)
                    .cashly(font: .callout)
            }
            .cashlyPadding()
        } header: {
            CashlyText("Score")
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
            .cashlyContentSurface(
                tint: variation.variationColor.opacity(0.2), in: .capsule)
    }

    func amountView(variationColor: Color) -> some View {
        CashlyVStack(spacing: .zero) {
            let expensesAmount = state.expensesAmount

            CashlyText(expensesAmount.formatted(.brl))
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
                .contentTransition(.numericText(value: expensesAmount))
        }
    }

    @ViewBuilder
    func warningCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
            CashlyHStack(spacing: .zero) {
                ForEach(categories.enumerated(), id: \.offset) { index, category in
                    let variation = state.categoryVariation(category: category)
                    let isEven = index.isMultiple(of: 2)
                    let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                    CashlySymbol(category.icon)
                        .cashly(font: .system(size: 18))
                        .cashly(color: .color(variation.variationColor))
                        .frame(width: 45, height: 45)
                        .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                            CashlyText(String(index + 1))
                                .cashly(font: .caption, weight: .bold)
                                .cashly(color: .color(variation.variationColor))
                                .cashlyPadding()
                                .cashly(background: .background)
                                .cashly(clip: .circle)
                                .cashlyPadding(.negative(.small))
                        }
                        .cashlyContentSurface(
                            tint: variation.variationColor.opacity(0.2), in: .circle
                        )
                        .offset(y: point)
                        .animation(
                            .linear.speed(0.5).repeatCount(
                                isAnimated ? .max : .zero, autoreverses: true),
                            value: isAnimated)
                }
            }
            .minimumScaleFactor(0.3)
            .cashly(alignment: .center)
        }
    }

}
