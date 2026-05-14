//
//  HomeScreen+PendingLoans.swift
//  CashlyKit
//
//  Loan tracker section. Surfaces every transaction whose
//  kind = .loan AND status is still pending so the user can mark
//  one settled (which stops it from counting against the budget)
//  without opening the full transaction edit screen.
//

import SwiftUI
import CashlyDomain
import CashlyResource

extension HomeScreen {
    @ViewBuilder
    var pendingLoansSection: some View {
        let loans = state.pendingLoans
        if !loans.isEmpty {
            Section {
                ForEach(loans, id: \.id) { loan in
                    CashlyHStack(spacing: .small) {
                        CashlySymbol("arrow.left.arrow.right")
                            .cashly(color: .color(.orange))
                            .cashly(font: .body)
                        CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                            CashlyText(loan.summary)
                                .cashly(font: .callout)
                            CashlyText(loan.date.date.cashly(with: .time))
                                .cashly(color: .textSecondary)
                                .cashly(font: .caption)
                        }
                        CashlySpacer()
                        CashlyText(CashlyCurrency.format(loan.amount))
                            .cashly(font: .callout, weight: .semibold)
                            .cashly(color: .color(.orange))
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            action(.main(.settleLoan(loan)))
                            CashlyHaptic.success.play()
                        } label: {
                            Label(
                                CashlyL10n.string("Mark settled"),
                                systemImage: "checkmark.circle"
                            )
                        }
                        .tint(.green)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(CashlyL10n.string("Loan")) \(loan.summary): \(CashlyCurrency.format(loan.amount))"
                    )
                }
            } header: {
                CashlyHStack {
                    CashlyText(CashlyL10n.string("Pending loans"))
                    CashlySpacer()
                    CashlyText(CashlyCurrency.format(state.pendingLoansAmount))
                        .cashly(color: .color(.orange))
                        .cashly(font: .caption, weight: .semibold)
                }
            }
        }
    }
}
