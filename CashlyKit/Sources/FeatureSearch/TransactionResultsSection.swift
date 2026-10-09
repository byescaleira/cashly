import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionResultsSection: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if !search.transactions.isEmpty {
            Section("Transações") {
                ForEach(search.transactions) { transaction in
                    Button {
                        open(.addTransaction(id: transaction.id), in: section)
                    } label: {
                        LabeledContent {
                            Text(transaction.money.formatted)
                                .foregroundStyle(
                                    transaction.kind == .income ? Color.green : Color.primary)
                        } label: {
                            Text(transaction.summary).foregroundStyle(Color.primary)
                            Text(
                                transaction.category.name.capitalized + " · "
                                    + transaction.date.formatted(date: .abbreviated, time: .omitted)
                            )
                        }
                    }
                }
            }
        }
    }
}
