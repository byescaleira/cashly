import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct HomeScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard
    @Environment(ReportsModel.self) private var reports
    @Environment(InsightsModel.self) private var insights

    public init() {}

    public var body: some View {
        AdaptiveList {
            DataStatusSection()
            SpendingSummarySection()
            ScoreSection()
            AvailableSection()
            OutlookSection()
            HistorySection()
            UnusualSection()
            FutureSection()
            VarianceSection()
            TopSpendingSection()
            EmptyTagsSection()
            TagsSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Início")
        .onChange(of: reports.syncKey, initial: true) { reports.sync() }
        .task(id: insights.key) { await insights.load() }
    }
}
