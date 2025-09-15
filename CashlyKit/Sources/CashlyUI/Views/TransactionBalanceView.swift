//
//  TransactionTransactionBalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation
import CashlyMock

struct TransactionBalanceView: CashlyView {
    @Environment(\.theme) var theme
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
                    statusView
                    amountView
                    biggestTagsView(tags: state.biggestTags)
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
    
    @ViewBuilder
    var statusView: some View {
        let status = state.filter.isFilteringByDate ? state.filter.startDate.string(with: CashlyDateFormatter.status) ?? "" : "All Data"
        CashlyText(status.uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .primary)
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(theme.color.primary.opacity(0.2)).interactive(), in: .capsule)
    }
    
    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.transactionsAmount.currency())
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
                .contentTransition(.numericText(value: state.transactionsAmount))
        }
    }
    
    @ViewBuilder
    func biggestTagsView(tags: [Tag]) -> some View {
        if !tags.isEmpty {
            CashlyVStack(spacing: .small) {
                GlassEffectContainer {
                    CashlyHStack(spacing: .zero) {
                        ForEach(tags.enumerated(), id: \.offset) { index, tag in
                            let isEven = index.isEven
                            let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                            CashlySymbol(tag.icon)
                                .cashly(font: .system(size: 18))
                                .cashly(color: .hex(tag.color))
                                .frame(width: 45, height: 45)
                                .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                                    CashlyText((index + 1).string)
                                        .cashly(font: .caption, weight: .bold)
                                        .cashly(color: .hex(tag.color))
                                        .cashlyPadding()
                                        .cashly(background: .background)
                                        .cashly(clip: .circle)
                                        .cashlyPadding(.negative(.small))
                                }
                                .cashly(glass: .clear.tint(Color(hex: tag.color).opacity(0.2)).interactive(), in: .circle)
                                .offset(y: point)
                                .animation(.linear.speed(0.5).repeatForever(autoreverses: true), value: isAnimated)
                        }
                    }
                }
                .minimumScaleFactor(0.3)
                
                CashlyText("\(tags.count) biggest tags".uppercased())
                    .cashly(font: .caption2, weight: .semibold)
                    .cashly(color: .textSecondary)
            }
            .cashly(alignment: .center)
        }
    }
    
    static var mock: some View {
        TransactionBalanceView()
    }
}

#Preview {
    CashlyList {
        TransactionBalanceView
            .cashlyPreview()
    }
}
