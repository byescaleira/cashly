import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionListToolbar: ToolbarContent {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(TransactionListModel.self) private var list

    var body: some ToolbarContent {
        ToolbarItem(placement: .leading) {
            if list.isSelecting {
                Button(
                    list.isAllSelected ? "Clear Selection" : "Select Loaded",
                    systemImage: list.isAllSelected ? "checklist.unchecked" : "checklist.checked"
                ) {
                    list.toggleSelectAll()
                }
                .tint(Color.primary)
            } else {
                UserMenu()
            }
        }
        if list.isSelecting {
            ToolbarItemGroup(placement: .primaryAction) {
                SelectionActions().disabled(finance.isLoading)
            }
            FixedToolbarSpacer(placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) { DoneButton() }
        } else if !session.users.isEmpty {
            ToolbarItemGroup(placement: .primaryAction) {
                FilterMenu()
                SelectButton()
            }
            FixedToolbarSpacer(placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) { AddButton() }
        }
    }
}

private struct AddButton: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Button("Add Transaction", systemImage: "plus") {
            open(.addTransaction(id: nil), in: section)
        }
        .tint(Color.primary)
        .disabled(finance.isLoading)
    }
}

private struct SelectButton: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(TransactionListModel.self) private var list

    var body: some View {
        if !list.items.isEmpty {
            Button("Select", systemImage: "checkmark.circle") {
                withAnimation(.bouncy(duration: 0.8)) { list.isSelecting = true }
            }
            .tint(Color.primary)
            .disabled(finance.isLoading)
        }
    }
}

private struct DoneButton: View {
    @Environment(TransactionListModel.self) private var list

    var body: some View {
        Button("Done", systemImage: "checkmark") {
            withAnimation(.bouncy(duration: 0.8)) { list.isSelecting = false }
        }
        .prominentButton()
    }
}

private struct SelectionActions: View {
    @Environment(SessionModel.self) private var session
    @Environment(TransactionListModel.self) private var list
    @Environment(\.pro) private var pro

    var body: some View {
        @Bindable var list = list
        ShareLink(item: list.shareMessage(participants: session.filter.participants)) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(list.selection.isEmpty)
        Button("Delete", systemImage: "trash") { pro.perform { list.isConfirmingDelete = true } }
            .disabled(list.selection.isEmpty)
            .alert("Delete Transactions", isPresented: $list.isConfirmingDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { Task { await list.deleteSelection() } }
            } message: {
                Text(
                    "The \(list.selection.count) selected transactions will be deleted. This can't be undone."
                )
            }
    }
}
