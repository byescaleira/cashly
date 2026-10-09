import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetCategorySection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            if !model.draft.categories.isEmpty {
                SymbolPicker(
                    items: model.draft.categories, selection: $model.draft.category, icon: \.icon,
                    color: { Color(hex: $0.color) }, name: \.name)
            }
            EmptyCategoriesSection()
        } header: {
            Text("Categoria").sectionTitle()
        }
    }
}
