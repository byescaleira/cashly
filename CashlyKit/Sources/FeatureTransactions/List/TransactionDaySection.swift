import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionDaySection: View {
    @Environment(TransactionListModel.self) private var list
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    let day: TransactionDay

    var body: some View {
        Section {
            ForEach(day.items) { transaction in
                Button {
                    open(.addTransaction(id: transaction.id), in: section)
                } label: {
                    TransactionRow(transaction: transaction)
                }
                .tag(transaction)
                .tint(Color.primary)
                .deleteAction { Task { await list.delete(transaction) } }
            }
        } header: {
            HStack {
                Text(day.date.formatted(.dateTime.day().month(.wide).year()))
                Spacer()
                Text(day.date.formatted(.dateTime.weekday(.wide)))
            }
            .textCase(.uppercase)
            .font(.footnote)
            .foregroundStyle(Color.secondary)
        }
    }
}
