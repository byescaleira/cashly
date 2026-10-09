import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionCategorySection: View {
    @Environment(TransactionEditorModel.self) private var model
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        @Bindable var model = model
        Section {
            if !model.draft.categories.isEmpty {
                CategorySelector(
                    categories: model.draft.categories, selection: $model.chosenCategory)
            }
            EmptyCategoriesSection()
            EmptyBudgetsSection()
        } header: {
            HStack {
                Text("Categoria").sectionTitle()
                Spacer()
                if let category = model.draft.category {
                    CategoryVariation(
                        category: category, amount: model.budgetImpact(in: session.filter.month))
                }
            }
        } footer: {
            if let message = model.budgetMessage(in: finance, month: session.filter.month) {
                Text(message)
                    .contentTransition(.numericText())
                    .animation(.bouncy, value: model.draft.amount)
            }
        }
    }
}
