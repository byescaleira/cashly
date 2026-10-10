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
    @Environment(IntelligenceModel.self) private var intelligence
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .home:
            ModelHost(DashboardModel(session: session, finance: finance)) {
                ModelHost(
                    ReportsModel(session: session, finance: finance, intelligence: intelligence)
                ) {
                    HomeScreen()
                }
            }
        case .transaction: TransactionListScreen()
        case .planning: CategoryListScreen()
        case .settings: SettingsScreen()
        case .search: SearchScreen()
        }
    }
}
