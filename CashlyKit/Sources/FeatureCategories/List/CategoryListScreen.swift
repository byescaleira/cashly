import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct CategoryListScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        @Bindable var goals = goals
        AdaptiveList {
            DataStatusSection()
            GoalsSummarySection()
            ForEach(goals.overview.groups, id: \.group) { entry in
                BudgetGroupSection(group: entry.group, items: entry.items)
            }
            UnbudgetedCategoriesSection()
            CategoriesSection()
        }
        .emptyState(.category, when: finance.categories.isEmpty && !finance.isLoading)
        .lineLimit(2)
        .font(.callout)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
            FixedToolbarSpacer()
            if !session.users.isEmpty {
                ToolbarItem {
                    Menu("Adicionar", systemImage: "plus") {
                        Button("Categoria", systemImage: "folder.badge.plus") {
                            open(.addCategory(id: nil), in: section)
                        }
                        Button("Orçamento", systemImage: "chart.pie") {
                            open(
                                .addBudget(
                                    id: nil, categoryID: nil, date: session.filter.startDate),
                                in: section)
                        }
                        .disabled(finance.categories.isEmpty)
                    }
                    .tint(Color.primary)
                    .disabled(finance.isLoading)
                }
            }
        }
        .confirmationDialog(
            goals.deletion?.title ?? "", isPresented: $goals.isConfirmingDeletion,
            titleVisibility: .visible, presenting: goals.deletion
        ) { _ in
            Button("Apagar", role: .destructive) { Task { await goals.confirmDeletion() } }
        } message: { deletion in
            Text(deletion.message)
        }
        .errorAlert($goals.error)
        .refreshable { await finance.load() }
        .navigationTitle("Metas")
    }
}
