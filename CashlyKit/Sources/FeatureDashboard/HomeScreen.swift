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
            VarianceSection()
            TopSpendingSection()
            EmptyTagsSection()
            TagsSection()
            ForecastSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Início")
        .onChange(of: dashboard.syncKey, initial: true) { dashboard.sync() }
        .task(id: dashboard.forecastKey) { await dashboard.loadForecast() }
    }
}
