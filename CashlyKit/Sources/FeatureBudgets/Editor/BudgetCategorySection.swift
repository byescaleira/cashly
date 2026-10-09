import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetCategorySection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            if !model.draft.categories.isEmpty {
                CategorySelector(
                    categories: model.draft.categories, selection: $model.draft.category)
            }
            EmptyCategoriesSection()
        } header: {
            Text("Categoria").sectionTitle()
        }
    }
}
