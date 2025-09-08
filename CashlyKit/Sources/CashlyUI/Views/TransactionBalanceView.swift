//
//  TransactionTransactionBalanceView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct TransactionBalanceView: CashlyView {
    @Environment(\.theme) var theme
    @Environment(\.mainState) var state
    
    @State var isAnimated: Bool = false
    
    var body: some View {
        Section {
            CashlyVStack(spacing: .medium) {
                transactionsAmountView
                amountView
                CashlyText("average per day".uppercased())
                    .cashly(font: .footnote, weight: .bold)
                    .cashly(color: .textSecondary)
                    .cashlyPadding(.extraSmall)
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .regular, in: .capsule)
                    .cashlyPadding(.top, .negative(.small))
                participantsView
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
    
    var transactionsAmountView: some View {
        CashlyText("\(state.transactions.count) transactions".uppercased())
            .cashly(font: .caption, weight: .bold)
            .cashly(color: .primary)
            .cashlyPadding()
            .cashlyPadding(.horizontal, .extraSmall)
            .cashly(glass: .clear.tint(theme.color.primary.opacity(0.2)), in: .capsule)
    }
    
    var amountView: some View {
        CashlyVStack(spacing: .zero) {
            CashlyText(state.transactionsAmount.currency())
                .cashly(font: .largeTitle, weight: .black)
                .cashly(color: .text)
                .contentTransition(.numericText(value: state.transactionsAmount))
            
            CashlyText(state.transactionsAverageAmount.currency())
                .cashly(font: .title, weight: .black)
                .cashly(color: .primary)
                .contentTransition(.numericText(value: state.budgetsAmount))
        }
    }
    
    @ViewBuilder
    var participantsView: some View {
        let transactionUsers = state.transactionUsers
        if !transactionUsers.isEmpty {
            CashlyVStack(spacing: .medium) {
                CashlyText("Top \(transactionUsers.count) highest spenders".uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                
                GlassEffectContainer {
                    CashlyHStack(spacing: .zero) {
                        ForEach(transactionUsers.enumerated(), id: \.offset) { index, user in
                            let isEven = index.isEven
                            let point: CGFloat = isAnimated ? (isEven ? -3 : 3) : (isEven ? 3 : -3)
                            CashlyAsyncImage(user.photo) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView().cashly(tint: .textSecondary)
                            }
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                                CashlyText((index + 1).string)
                                    .cashly(font: .caption, weight: .bold)
                                    .cashly(color: .primary)
                                    .cashlyPadding()
                                    .cashly(background: .background)
                                    .cashly(clip: .circle)
                                    .cashlyPadding(.negative(.small))
                            }
                            .cashlyPadding(.extraSmall)
                            .cashly(glass: .regular.tint(theme.color.pressed.opacity(0.2)), in: .circle)
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
        TransactionBalanceView()
    }
}

#Preview {
    CashlyList {
        TransactionBalanceView
            .cashlyPreview()
    }
}
