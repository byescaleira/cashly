import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct CategoryListScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        AdaptiveList {
            CategoryBalanceSection()
            EmptyCategoriesSection()
            EmptyBudgetsSection()
            EmptyUsersSection()
            DataStatusSection()
            UnbudgetedCategoriesSection()
            BudgetedCategoriesSection()
        }
        .lineLimit(2)
        .font(.callout)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
            FixedToolbarSpacer()
            if !session.users.isEmpty {
                ToolbarItem {
                    Button("Adicionar categoria", systemImage: "plus") {
                        open(.addCategory(id: nil), in: section)
                    }
                    .tint(Color.primary)
                    .disabled(finance.isLoading)
                }
            }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Planejamento")
    }
}
