import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct CategoryDetailHeader: View {
    @Environment(FinanceModel.self) private var finance
    let category: CashlyDomain.Category

    var body: some View {
        Section {
            if let summary = finance.budget(for: category)?.summary {
                Text(summary).frame(maxWidth: .infinity).padding(8)
            }
        } header: {
            VStack(spacing: 16) {
                CategoryBadge(category: category, diameter: 70, ring: 5)
                VStack(spacing: 0) {
                    Text(finance.budgetsAmount(for: category).formatted(.appCurrency))
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.primary)
                        .amountLine()
                    Text(finance.expensesAmount(for: category).formatted(.appCurrency))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.secondary)
                        .amountLine()
                }
                CategoryVariation(category: category).scaleEffect(1.2)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}
