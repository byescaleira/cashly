import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CategoriesSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Section {
            ForEach(goals.categories) { category in
                let budgets = goals.budgets(for: category)
                Button {
                    open(.detailCategory(id: category.id), in: section)
                } label: {
                    HStack(spacing: 14) {
                        CategoryBadge(category: category)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name).font(.callout.weight(.semibold))
                            Text(
                                caption(
                                    budgets: budgets.count,
                                    planned: finance.budgetsAmount(for: category))
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(finance.expensesAmount(for: category).formatted(.appCurrency))
                            .font(.callout.weight(.semibold))
                            .amountLine()
                        Image(systemName: "chevron.forward").foregroundStyle(.disabled)
                    }
                }
                .tint(Color.primary)
                .contextMenu {
                    Button("Editar", systemImage: "square.and.pencil") {
                        open(.addCategory(id: category.id), in: section)
                    }
                    Button("Novo orçamento", systemImage: "plus.circle") {
                        open(
                            .addBudget(
                                id: nil, categoryID: category.id, date: session.filter.startDate),
                            in: section)
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
            Text("O valor à direita é o gasto no período.")
        }
    }

    private func caption(budgets: Int, planned: Double) -> String {
        switch budgets {
        case 0: "Sem orçamento"
        case 1: "1 orçamento · \(planned.formatted(.appCurrency))"
        default: "\(budgets) orçamentos · \(planned.formatted(.appCurrency))"
        }
    }
}
