import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct HomeScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    public init() {}

    public var body: some View {
        AdaptiveList {
            EmptyUsersSection()
            DataStatusSection()
            EmptyCategoriesSection()
            EmptyBudgetsSection()
            SpendingSummarySection()
            ScoreSection()
            AvailableSection()
            TopSpendingSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Início")
        .onChange(of: dashboard.syncKey, initial: true) { dashboard.sync() }
    }
}
