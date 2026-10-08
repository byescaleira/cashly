import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct CategoryBalanceView: View {
    @Environment(MainViewModel.self) var state

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var isAnimated: Bool = false

    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
            !state.budgets.isEmpty
        {
            Section {

            } header: {
                CashlyVStack(spacing: .medium) {
                    statusView
                    amountView
                    biggestCategoriesView(categories: state.biggestCategories)
                }
                .cashly(alignment: .center)
                .frame(maxWidth: .infinity)
                .cashlyPadding(.top, .medium)
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

    @ViewBuilder
    var statusView: some View {
        let status =
            state.filter.isFilteringByDate
            ? state.filter.startDate.formatted(.dateTime.month(.wide).year()) : "All Data"
        CashlyText(status.uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .primary)
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashlyContentSurface(tint: Color.accentColor.opacity(0.2), in: .capsule)
    }

    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.budgetsAmount.formatted(.brl))
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
                .contentTransition(.numericText(value: state.expensesAmount))
        }
    }

    @ViewBuilder
    func biggestCategoriesView(categories: [CashlyDomain.Category]) -> some View {
        if !categories.isEmpty {
            CashlyHStack(spacing: .zero) {
                ForEach(categories.enumerated(), id: \.offset) { index, category in
                    let isEven = index.isMultiple(of: 2)
                    let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                    CashlySymbol(category.icon)
                        .cashly(font: .system(size: 18))
                        .cashly(color: .hex(category.color))
                        .frame(width: 45, height: 45)
                        .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                            CashlyText(String(index + 1))
                                .cashly(font: .caption, weight: .bold)
                                .cashly(color: .hex(category.color))
                                .cashlyPadding()
                                .cashly(background: .background)
                                .cashly(clip: .circle)
                                .cashlyPadding(.negative(.small))
                        }
                        .cashlyContentSurface(
                            tint: Color(hex: category.color).opacity(0.2), in: .circle
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
