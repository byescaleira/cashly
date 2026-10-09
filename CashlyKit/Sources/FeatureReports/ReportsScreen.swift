import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct ReportsScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports

    public init() {}

    public var body: some View {
        AdaptiveList {
            EmptyUsersSection()
            DataStatusSection()
            EmptyCategoriesSection()
            ForecastSection()
            TrainingPromptSection()
            VarianceSection()
            EmptyTagsSection()
            TagsSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem { FilterMenu() }
        }
        .refreshable { await finance.load() }
        .navigationTitle("Relatórios")
        .onChange(of: reports.syncKey, initial: true) { reports.sync() }
        .task(id: reports.forecastKey) { await reports.loadForecast() }
    }
}
