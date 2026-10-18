import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct HomeScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard
    @Environment(ReportsModel.self) private var reports
    @Environment(InsightsModel.self) private var insights
    @Environment(SummaryModel.self) private var summary
    @Environment(\.pro) private var pro
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        AdaptiveList {
            DataStatusSection()
            SpendingSummarySection()
            SummarySection()
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
        .animation(reduceMotion ? nil : .smooth, value: summary.summary)
        .fontDesign(.rounded)
        .toolbar { HomeToolbar() }
        .refreshable { await finance.load() }
        .navigationTitle("Home")
        .onChange(of: reports.syncKey, initial: true) { reports.sync() }
        .task(id: summary.trigger(insights.key, isPro: pro.isPro)) {
            await insights.load()
            await summary.load(from: insights, isPro: pro.isPro)
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                insights.checkDay()
            }
        }
    }
}
