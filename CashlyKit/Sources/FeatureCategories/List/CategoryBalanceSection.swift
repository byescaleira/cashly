import FeatureCore
import SwiftUI

struct CategoryBalanceSection: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            PeriodSummaryHeader(
                amount: finance.budgetsAmount,
                items: finance.biggestCategories.map {
                    .init(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color)
                })
        }
    }
}
