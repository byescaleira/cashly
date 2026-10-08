import CashlyDomain
import CashlyPresentation
import CashlyUI
import FeatureCore
import SwiftUI

struct SectionScreen: View {
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .intelligence: IntelligenceScreen()
        case .category: CategoryScreen()
        case .home: HomeScreen()
        case .transaction: TransactionScreen()
        }
    }
}
