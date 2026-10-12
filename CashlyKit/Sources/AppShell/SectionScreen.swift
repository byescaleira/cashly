import FeatureCategories
import FeatureCore
import FeatureDashboard
import FeatureSearch
import FeatureSettings
import FeatureTransactions
import SwiftUI

struct SectionScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .home:
            ModelHost(DashboardModel(session: session, finance: finance)) {
                ModelHost(
                    ReportsModel(finance: finance)
                ) {
                    ModelHost(InsightsModel(session: session, finance: finance)) { HomeScreen() }
                }
            }
        case .transaction: TransactionListScreen()
        case .planning:
            ModelHost(GoalsModel(session: session, finance: finance)) { CategoryListScreen() }
        case .settings: SettingsScreen { MCPSettingsSlot() }
        case .search: SearchScreen()
        }
    }
}
