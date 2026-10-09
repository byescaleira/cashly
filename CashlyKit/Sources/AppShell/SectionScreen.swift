import CashlyDomain
import CashlyUI
import FeatureCategories
import FeatureCore
import FeatureTransactions
import SwiftUI

struct SectionScreen: View {
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .intelligence: IntelligenceScreen()
        case .category: CategoryListScreen()
        case .home: HomeScreen()
        case .transaction: TransactionListScreen()
        }
    }
}
