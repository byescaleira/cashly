import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetCategorySection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            if model.draft.categories.isEmpty {
                MissingDataView(.category)
            } else {
                SymbolPicker(
                    items: model.draft.categories, selection: $model.draft.category, icon: \.icon,
                    color: { Color(hex: $0.color) }, name: \.name)
            }
        } header: {
            Text("Category").sectionTitle()
        }
    }
}
