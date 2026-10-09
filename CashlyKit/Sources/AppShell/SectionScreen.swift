import CashlyUI
import FeatureCategories
import FeatureCore
import FeatureDashboard
import FeatureTransactions
import SwiftUI

struct SectionScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .intelligence: IntelligenceScreen()
        case .category: CategoryListScreen()
        case .home:
            ModelHost(
                DashboardModel(session: session, finance: finance, intelligence: intelligence)
            ) {
                HomeScreen()
            }
        case .transaction: TransactionListScreen()
        }
    }
}
