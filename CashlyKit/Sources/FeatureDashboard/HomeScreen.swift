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
            ProShowcaseSection(.home)
            ShopSpotlightSection()
            OutlookSection()
            VarianceSection()
            HistorySection()
            UnusualSection()
            ChangesSection()
            TopSpendingSection()
            MerchantsSection()
            SmallPurchasesSection()
            WeekdaySection()
            EmptyTagsSection()
            TagsSection()
            RecurringSection()
            BudgetIdeasSection()
            FutureSection()
        }
        .fontDesign(.rounded)
        .toolbar { HomeToolbar() }
        .refreshable { await finance.load() }
        .navigationTitle("Home")
        .onChange(of: reports.syncKey, initial: true) { reports.sync() }
        .task(id: insights.key) { await insights.load() }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                insights.checkDay()
            }
        }
    }
}
