import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionBalanceSection: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            PeriodSummaryHeader(
                amount: finance.expensesAmount,
                items: finance.biggestTags.map {
                    .init(id: $0.id, name: $0.name, icon: $0.icon, color: Color(hex: $0.color))
                })
        }
    }
}
