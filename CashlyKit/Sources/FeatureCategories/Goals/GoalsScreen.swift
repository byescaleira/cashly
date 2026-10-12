import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct GoalsScreen: View {
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
            BudgetsOverviewSection()
            CategoriesSection()
        }
        .emptyState(.category, when: finance.categories.isEmpty && !finance.isLoading)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
            FixedToolbarSpacer()
            if !session.users.isEmpty {
                ToolbarItem {
                    Button("New Category", systemImage: "plus") {
                        open(.addCategory(id: nil), in: section)
                    }
                    .tint(Color.primary)
                    .disabled(finance.isLoading)
                }
            }
        }
        .deletionDialog(goals)
        .errorAlert($goals.error)
        .refreshable { await finance.load() }
        .navigationTitle("Goals")
    }
}

extension View {
    func deletionDialog(_ goals: GoalsModel) -> some View {
        @Bindable var goals = goals
        return confirmationDialog(
            goals.deletion?.title ?? "", isPresented: $goals.isConfirmingDeletion,
            titleVisibility: .visible, presenting: goals.deletion
        ) { _ in
            Button("Delete", role: .destructive) { Task { await goals.confirmDeletion() } }
        } message: { deletion in
            Text(deletion.message)
        }
    }
}
