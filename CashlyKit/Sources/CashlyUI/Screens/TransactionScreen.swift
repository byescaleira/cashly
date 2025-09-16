//
//  TransactionScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import RyzeArchitecture
import CashlyMock
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct TransactionScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            TransactionBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            EmptyTransactionView()
            transactionsSection
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
            ToolbarItemGroup {
                FilterItemView()
                addButton
            }
        }
        .environment(\.isLoading, state.isLoading)
        .onAppear { action(.main(.fetch)) }
        .navigationTitle("Transactions")
    }
    
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
    
    @ViewBuilder
    var addButton: some View {
        if !state.users.isEmpty {
            CashlyButton {
                router.route(to: .addTransaction(state: .new()))
            } label: {
                CashlySymbol("plus")
                    .cashly(font: .headline, weight: .bold)
            }
            .disabled(state.isLoading)
        }
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

