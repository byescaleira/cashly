import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct HomeScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard
    @Environment(ReportsModel.self) private var reports

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
            TrainingPromptSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Início")
        .onChange(of: dashboard.syncKey, initial: true) { dashboard.sync() }
        .onChange(of: reports.syncKey, initial: true) { reports.sync() }
        .task(id: reports.forecastKey) { await reports.loadForecast() }
    }
}
