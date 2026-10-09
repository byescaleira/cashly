import FeatureCore
import SwiftUI

struct BudgetConflictLink: View {
    @Environment(TransactionEditorModel.self) private var model
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if let budget = model.conflictedBudget(in: finance) {
            Section {
                Button("Resolver conflito de orçamento") {
                    open(
                        .budgetConflict(categoryID: budget.category.id, month: budget.month),
                        in: section)
                }
            }
        }
    }
}
