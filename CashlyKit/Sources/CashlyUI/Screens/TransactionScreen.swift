//
//  TransactionScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct TransactionScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            TransactionBalanceView()
            transactionsSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItem { addButton }
        }
        .environment(\.isLoading, state.isLoading)
        .navigationTitle("Transactions")
    }
    
    @ViewBuilder
    var transactionsSection: some View {
        let sections = state.transactionSections
        ForEach(sections.indices, id: \.self) {
            let transactions = sections[$0]
            Section {
                ForEach(transactions.indices, id: \.self) { index in
                    let transaction = transactions[index]
                    transactionView(transaction: transaction)
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
                .overlay(alignment: .topTrailing) {
                    statusView(
                        participants: transaction.participants,
                        status: transaction.status
                    )
                }
            
            CashlyVStack(alignment: .leading, spacing: .zero) {
                CashlyHStack {
                    CashlyText(transaction.date.date.cashly(with: .time))
                    participantsView(participants: transaction.participants)
                }
                
                CashlyText(transaction.summary)
                    .cashly(color: .textSecondary)
            }
            .cashly(font: .callout)
            
            CashlySpacer()
            
            CashlyVStack(alignment: .trailing, spacing: .zero) {
                CashlyText(transaction.amount.currency())
                    
                if !transaction.participants.isEmpty {
                    CashlyText(transaction.splitValue?.currency())
                        .cashly(color: .textSecondary)
                }
            }
            .cashly(font: .callout, weight: .semibold)
        }
        .lineLimit(2)
    }
    
    func categoryIcon(category: CashlyDomain.Category) -> some View {
        CashlySymbol(category.icon)
            .cashly(font: .system(size: 22))
            .cashly(color: .hex(category.color))
            .frame(width: 50, height: 50)
            .cashly(background: .color((Color(hex: category.color)).opacity(0.2)))
            .cashly(clip: .circle)
    }
    
    @ViewBuilder
    func statusView(
        participants: [Participant],
        status: TransactionStatus
    ) -> some View {
        if participants.isEmpty, status != .settled {
            CashlySymbol(status.icon)
                .cashly(font: .system(size: 14), weight: .bold)
                .cashly(color: .white)
                .cashlyPadding(.extraSmall)
                .cashly(glass: .clear.tint(status.color), in: .circle)
                .cashlyPadding(.negative(.extraSmall))
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
                        .frame(width: 12, height: 12)
                        .cashly(if: index != .zero) {
                            $0.cashlyPadding(.leading, .negative(.extraSmall))
                        }
                }
            }
        }
    }
    
    var addButton: some View {
        CashlyButton {
            
        } label: {
            CashlySymbol("plus")
                .cashly(font: .headline, weight: .bold)
        }
        .disabled(state.isLoading)
        .cashly(tint: .primary)
    }
    
    public static var mock: some View {
        TransactionScreen()
    }
}

#Preview {
    NavigationView {
        TransactionScreen
            .cashlyPreview()
    }
}

