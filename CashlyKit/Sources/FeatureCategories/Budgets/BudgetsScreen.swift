import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct BudgetsScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        @Bindable var goals = goals
        AdaptiveList {
            BudgetsEmptySection()
            BudgetMonthSection()
            BudgetSections()
            UnbudgetedSection()
        }
        .emptyState(.category, when: finance.categories.isEmpty && !finance.isLoading)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem { FilterMenu() }
            FixedToolbarSpacer()
            ToolbarItem {
                Button("New Budget", systemImage: "plus") {
                    open(goals.newBudgetRoute, in: section)
                }
                .tint(Color.primary)
                .disabled(!goals.canCreateBudget)
            }
        }
        .deletionDialog(goals)
        .errorAlert($goals.error)
        .refreshable { await finance.load() }
        .navigationTitle("Budgets")
    }
}

struct UnbudgetedSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let categories = finance.categoriesWithoutBudgets
        if !categories.isEmpty, session.filter.isFilteringByDate {
            Section {
                FlowLayout(spacing: .spaceS) {
                    ForEach(categories) { category in
                        let color = Color(hex: category.color)
                        Button {
                            open(goals.budgetRoute(for: category), in: section)
                        } label: {
                            HStack(spacing: .spaceXS) {
                                Image(systemName: "plus")
                                Text(category.name)
                            }
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(color)
                            .padding(.horizontal, .spaceM)
                            .padding(.vertical, .spaceS)
                            .background(color.opacity(.opacityFill), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Create a \(category.name) budget")
                    }
                }
                .padding(.vertical, .space2XS)
            } header: {
                Text("No Budget").sectionTitle()
            } footer: {
                Text("Tap a category to set how much you want to spend on it this month.")
            }
        }
    }
}
