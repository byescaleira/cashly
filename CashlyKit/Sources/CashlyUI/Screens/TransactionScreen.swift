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
    @Environment(CashlyStore<MainReducer, MainMiddleware>.self) var store
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State private var editMode = EditMode.inactive
    @State private var selection: Set<CashlyDomain.Transaction> = []
    
    public init() {}
    
    public var body: some View {
        CashlyList(selection: $selection) {
            TransactionBalanceView()
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
            EmptyUserView()
            transactionsSection
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if editMode != .active {
                    UserItemView()
                }
                selectAllButton
            }
            
            ToolbarItemGroup {
                editButton
                FilterItemView()
            }
            
            ToolbarSpacer(.fixed)
            ToolbarItemGroup {
                addButton
                
                shareButton
                removeButton
                checkButton
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
    
    @ViewBuilder
    var addButton: some View {
        if !state.users.isEmpty, editMode == .inactive {
            CashlyButton {
                router.route(to: .addTransaction(state: .new()))
            } label: {
                CashlySymbol("plus")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }
    
    @ViewBuilder
    var editButton: some View {
        if !state.users.isEmpty, editMode == .inactive, !state.transactions.isEmpty {
            CashlyButton {
                withAnimation(.bouncy(duration: 0.8)) {
                    editMode = .active
                }
            } label: {
                CashlySymbol("checkmark.circle")
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }
    
    @ViewBuilder
    var selectAllButton: some View {
        let isAllSelected = selection.count == state.transactions.count
        if editMode == .active {
            CashlyButton {
                selection = isAllSelected ? [] : Set(state.transactions)
            } label: {
                CashlyText(isAllSelected ? "Clear Selection" : "Select All")
                    .cashly(font: .body, weight: .bold)
                    .cashly(color: .text)
            }
            .disabled(state.isLoading)
        }
    }
    
    @ViewBuilder
    var shareButton: some View {
        if editMode == .active {
            ShareLink(item: selection.shareMessage(participants: state.filter.participants)) {
                CashlySymbol("square.and.arrow.up")
                    .cashly(color: selection.isEmpty ? .disabled : .text)
            }
            .disabled(state.isLoading)
            .disabled(selection.isEmpty)
        }
    }
    
    @State var showDeleteAlert = false
    
    @ViewBuilder
    var removeButton: some View {
        if editMode == .active {
            CashlyButton {
                showDeleteAlert = true
            } label: {
                CashlySymbol("trash")
                    .cashly(color: selection.isEmpty ? .disabled : .text)
            }
            .disabled(state.isLoading)
            .disabled(selection.isEmpty)
            .alert("Delete Transactions", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    action(.main(.removeTransactions(selection)))
                }
            } message: {
                CashlyText("Are you sure you want to delete \(selection.count) selected transaction\(selection.count == 1 ? "" : "s")? This action cannot be undone.")
            }

        }
    }
    
    @ViewBuilder
    var checkButton: some View {
        if editMode == .active {
            CashlyButton {
                withAnimation(.bouncy(duration: 0.8)) {
                    editMode = .inactive
                }
            } label: {
                CashlySymbol("checkmark")
            }
            .disabled(state.isLoading)
            .buttonStyle(.glassProminent)
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

