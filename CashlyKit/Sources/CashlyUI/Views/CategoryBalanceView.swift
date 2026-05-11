//
//  CategoryBalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

struct CategoryBalanceView: CashlyView {

    @Environment(\.mainState) var state

    @State var isAnimated: Bool = false

    @ViewBuilder
    var body: some View {
        if !state.categories.isEmpty,
           !state.budgets.isEmpty {
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
            .onAppear {
                isAnimated = false
                Task {
                    try await Task.sleep(for: .seconds(1))
                    isAnimated = true
                }
            }
        }
    }

    @ViewBuilder
    var statusView: some View {
        let status = state.filter.isFilteringByDate ? state.filter.startDate.string(with: .cashly(.status)) ?? "" : "All Data"
        CashlyText(status.uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .primary)
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(Color.accentColor.opacity(0.2)).interactive(), in: .capsule)
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
                                .animation(.linear.speed(0.5).repeatCount(isAnimated ? .max : .zero, autoreverses: true), value: isAnimated)
                        }
                    }
                }
                .minimumScaleFactor(0.3)
                .cashly(alignment: .center)
        }
    }

    static var mock: some View {
        CategoryBalanceView()
    }
}

#if DEBUG
#Preview {
    CashlyList {
        CategoryBalanceView
            .cashlyPreview()
    }
}
#endif
