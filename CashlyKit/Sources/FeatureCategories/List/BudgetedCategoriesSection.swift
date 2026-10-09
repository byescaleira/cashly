import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetedCategoriesSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let categories = finance.categoriesWithBudgets
        if !categories.isEmpty {
            Section {
                ForEach(categories) { category in
                    Button {
                        open(.detailCategory(id: category.id), in: section)
                    } label: {
                        CategoryRow(category: category)
                    }
                    .tint(Color.primary)
                    .editAction { open(.addCategory(id: category.id), in: section) }
                }
            } header: {
                Text("Orçamentos").sectionTitle()
            }
        }
    }
}
