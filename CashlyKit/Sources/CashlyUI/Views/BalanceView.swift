import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import Foundation
import SwiftUI

struct BalanceView: View {
    @Environment(SessionModel.self) var session
    @Environment(FinanceModel.self) var finance

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var isAnimated: Bool = false

    @ViewBuilder
    var body: some View {
        if !session.users.isEmpty {
            Group {
                balanceSection
                scoreSection
            }
            .environment(\.isLoading, finance.isLoading)
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
                let variation = finance.variation
                variationView(variation: variation)
                let warningCategories = finance.warningCategories
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
            let health = finance.health
            let level = health.level

            CashlyVStack(alignment: .leading, spacing: .medium) {
                CashlyHStack(spacing: .small) {
                    CashlyText(String(health.score))
                        .cashly(font: .title, weight: .bold)
                    CashlyText("/  " + String(BudgetHealth.maximumScore))
                        .cashly(font: .footnote)
                        .cashly(color: .textSecondary)
                        .cashlyPadding(.bottom, .negative(.small))
                    Spacer()

                    CashlyText(level.title.uppercased())
                        .cashly(font: .caption2, weight: .bold)
                        .cashly(color: .color(level.color))
                        .cashlyPadding()
                        .cashlyPadding(.horizontal, .extraSmall)
                        .cashlyContentSurface(tint: level.color.opacity(0.2), in: .capsule)
                }

                CashlyHStack(spacing: .small) {
                    ForEach(BudgetHealth.Level.allCases, id: \.self) { item in
                        ProgressView(
                            value: item == level ? item.progress(for: health.score) : 1.0, total: 1
                        )
                        .cashly(
                            tint: .color(
                                health.score > item.scores.upperBound || item == level
                                    ? level.color : .clear))
                    }
                }

                CashlyText(level.summary)
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
            let expensesAmount = finance.expensesAmount

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
                    let variation = finance.categoryVariation(category: category)
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
