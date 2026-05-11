//
//  TransactionScreen+Rows.swift
//  CashlyKit
//
//  //  row + section views extracted from TransactionScreen.swift.
//

import SwiftUI
import CashlyDomain

extension TransactionScreen {
    @ViewBuilder
    var transactionsSection: some View {
        let sections = state.transactionSections
        ForEach(sections.indices, id: \.self) {
            let transactions = sections[$0]
            Section {
                ForEach(transactions) { transaction in
                    CashlyButton {
                        router.route(to: .addTransaction(state: .edit(id: transaction.id)))
                    } label: {
                        transactionView(transaction: transaction)
                    }
                    .tag(transaction)
                    .cashly(tint: .text)
                    .cashlyDelete { action(.main(.removeTransaction(transaction))) }
                }
            } header: {
                CashlyHStack {
                    CashlyText(transactions.first?.date.date.cashly(with: .transactionSection))
                    CashlySpacer()
                    CashlyText(transactions.first?.date.date.cashly(with: .weekDay))
                }
                .textCase(.uppercase)
                .cashly(font: .footnote)
                .cashly(color: .textSecondary)
            }
        }
    }

    func transactionView(transaction: CashlyDomain.Transaction) -> some View {
        CashlyHStack(spacing: .medium) {
            categoryIcon(category: transaction.budget.category)
                .overlay(alignment: .bottomTrailing) {
                    statusView(
                        participants: transaction.participants,
                        status: transaction.status
                    )
                }

            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(transaction.summary)

                CashlyHStack {
                    CashlyText(transaction.date.date.cashly(with: .time))
                    participantsView(participants: transaction.participants)
                }
                .cashly(color: .textSecondary)
            }
            .cashly(font: .callout)

            CashlySpacer()

            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                if !transaction.participants.isEmpty {
                    CashlyText(transaction.splitValue?.currency())
                } else if let paymentPlan = transaction.paymentsPlan {
                    CashlyHStack(spacing: .extraSmall) {
                        CashlyText(paymentPlan.string + "x")
                            .cashly(color: .textSecondary)
                        CashlyText((transaction.amount / paymentPlan.double).currency())
                    }
                }

                CashlyText(transaction.amount.currency())
                    .cashly(color: transaction.participants.isEmpty && transaction.paymentsPlan == nil ? .text : .textSecondary)
            }
            .cashly(font: .callout, weight: .semibold)

            CashlySymbol("chevron.forward")
                .cashly(color: .disabled)
        }
        .lineLimit(2)
    }

    func categoryIcon(category: CashlyDomain.Category) -> some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 18))
            .cashly(color: .hex(category.color))
            .frame(width: 40, height: 40)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
    }

    @ViewBuilder
    func statusView(
        participants: [Participant],
        status: TransactionStatus
    ) -> some View {
        if status != .settled {
            CashlySymbol(status.icon)
                .cashly(font: .system(size: 10), weight: .bold)
                .cashly(color: .white)
                .cashlyPadding(.extraSmall)
                .cashly(glass: .clear.tint(status.color), in: .circle)
                .cashlyPadding([.bottom, .trailing], .negative(.extraSmall))
        }
    }

    @ViewBuilder
    func participantsView(participants: [Participant]) -> some View {
        if !participants.isEmpty {
            CashlyHStack(spacing: .zero) {
                ForEach(participants.indices, id: \.self) { index in
                    let participant = participants[index]
                    Circle()
                        .fill(participant.status.color)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }
            }
        }
    }
}
