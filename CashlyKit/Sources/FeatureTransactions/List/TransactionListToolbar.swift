import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionListToolbar: ToolbarContent {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(TransactionListModel.self) private var list
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some ToolbarContent {
        ToolbarItem(placement: .leading) {
            if list.isSelecting {
                Button(list.isAllSelected ? "Clear Selection" : "Select Loaded") {
                    list.toggleSelectAll()
                }
                .font(.body.weight(.bold))
                .tint(Color.primary)
            } else {
                UserMenu()
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            if !session.users.isEmpty, !list.isSelecting, !list.items.isEmpty {
                Button("Select", systemImage: "checkmark.circle") {
                    withAnimation(.bouncy(duration: 0.8)) { list.isSelecting = true }
                }
                .disabled(finance.isLoading)
            }
        }
        ToolbarItem { FilterMenu() }
        ToolbarItemGroup(placement: .primaryAction) {
            if list.isSelecting {
                SelectionActions().disabled(finance.isLoading)
            } else if !session.users.isEmpty {
                Button("Add Transaction", systemImage: "plus") {
                    open(.addTransaction(id: nil), in: section)
                }
                .tint(Color.primary)
                .disabled(finance.isLoading)
            }
        }
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
        Button("Done", systemImage: "checkmark") {
            withAnimation(.bouncy(duration: 0.8)) { list.isSelecting = false }
        }
        .prominentButton()
    }
}
