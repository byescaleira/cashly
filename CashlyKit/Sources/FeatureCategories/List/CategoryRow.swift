import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct CategoryRow: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let category: CashlyDomain.Category

    var body: some View {
        let budgeted = finance.budgetsAmount(for: category)
        let spent = finance.expensesAmount(for: category)
        HStack(spacing: 16) {
            AdaptiveRow {
                CategoryBadge(category: category)
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name).font(.callout.weight(.semibold))
                    if let summary = finance.budget(for: category)?.summary {
                        Text(summary).foregroundStyle(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(
                    alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
                    spacing: 4
                ) {
                    CategoryVariation(category: category)
                        .scaleEffect(0.7)
                        .padding(.trailing, -6)
                    if budgeted > .zero {
                        Text(budgeted.formatted(.appCurrency)).font(.callout.weight(.semibold))
                    }
                    if spent > .zero {
                        Text(spent.formatted(.appCurrency))
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .amountLine()
                .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
            }
            Image(systemName: "chevron.forward").foregroundStyle(.disabled)
        }
    }
}
