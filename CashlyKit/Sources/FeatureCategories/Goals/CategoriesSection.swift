import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CategoriesSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Section {
            ForEach(goals.categories) { category in
                Button {
                    open(.addCategory(id: category.id), in: section)
                } label: {
                    HStack(spacing: 14) {
                        CategoryBadge(category: category)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name).font(.body.weight(.semibold))
                            Text(goals.caption(for: category))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(finance.expensesAmount(for: category).formatted(.appCurrency))
                            .font(.callout.weight(.semibold))
                            .amountLine()
                    }
                    .contentShape(.rect)
                }
                .tint(Color.primary)
                .swipeActions {
                    Button("Apagar", systemImage: "trash", role: .destructive) {
                        goals.deletion = .category(category)
                    }
                    Button("Editar", systemImage: "square.and.pencil") {
                        open(.addCategory(id: category.id), in: section)
                    }
                }
                .contextMenu {
                    Button("Editar", systemImage: "square.and.pencil") {
                        open(.addCategory(id: category.id), in: section)
                    }
                    Divider()
                    Button("Apagar", systemImage: "trash", role: .destructive) {
                        goals.deletion = .category(category)
                    }
                }
            }
        } header: {
            Text("Categorias").sectionTitle()
        } footer: {
            Text("Toque para editar e deslize para apagar. O valor é o gasto no período.")
        }
    }
}
