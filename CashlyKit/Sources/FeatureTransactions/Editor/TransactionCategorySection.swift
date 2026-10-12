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
            if model.draft.categories.isEmpty {
                MissingDataView(.category)
            } else {
                SymbolPicker(
                    items: model.draft.categories, selection: $model.chosenCategory, icon: \.icon,
                    color: { Color(hex: $0.color) }, name: \.name)
            }
        } header: {
            HStack {
                Text("Category").sectionTitle()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
