//
//  TransactionScreen+Toolbar.swift
//  CashlyKit
//
//  Wave 7 G019: toolbar buttons extracted from TransactionScreen.swift.
//

import SwiftUI
import CashlyDomain
import CashlyResource

extension TransactionScreen {
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
            .alert(CashlyL10n.string("Delete Transactions"), isPresented: $showDeleteAlert) {
                Button(CashlyL10n.string("Cancel"), role: .cancel) { }
                Button(CashlyL10n.string("Delete"), role: .destructive) {
                    action(.main(.removeTransactions(selection)))
                }
            } message: {
                let count = selection.count
                CashlyText(CashlyL10n.string("Are you sure you want to delete \(count) selected transactions? This action cannot be undone."))
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
}
