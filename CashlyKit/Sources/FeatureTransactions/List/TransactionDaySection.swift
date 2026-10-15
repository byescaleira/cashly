import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionDaySection: View {
    let day: TransactionDay

    var body: some View {
        Section {
            ForEach(day.items) { TransactionDayRow(transaction: $0) }
        } header: {
            AdaptiveStack(spacing: .space2XS) {
                Text(day.date.formatted(.dateTime.day().month(.wide).year().locale(.app)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(day.date.formatted(.dateTime.weekday(.wide).locale(.app)))
            }
            .textCase(.uppercase)
            .font(.footnote)
            .foregroundStyle(Color.secondary)
        }
    }
}

private struct TransactionDayRow: View {
    @Environment(TransactionListModel.self) private var list
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.isGroupedColumn) private var isGroupedColumn
    let transaction: CashlyDomain.Transaction

    var body: some View {
        let isPicking = isGroupedColumn && list.isSelecting
        Button {
            if isPicking {
                list.toggleSelection(of: transaction)
            } else {
                open(.addTransaction(id: transaction.id), in: section)
            }
        } label: {
            HStack(spacing: .spaceM) {
                if isPicking { SelectionMark(isSelected: list.isSelected(transaction)) }
                TransactionRow(transaction: transaction)
            }
            .contentShape(.rect)
        }
        .tag(transaction)
        .tint(Color.primary)
        .accessibilityAddTraits(isPicking && list.isSelected(transaction) ? .isSelected : [])
        .deleteAction { Task { await list.delete(transaction) } }
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await list.delete(transaction) }
            }
        }
    }
}
