import CashlyDomain
import FeatureCore
import SwiftUI

struct CategoryRow: View {
    @Environment(FinanceModel.self) private var finance
    let category: CashlyDomain.Category

    var body: some View {
        let budgeted = finance.budgetsAmount(for: category)
        let spent = finance.expensesAmount(for: category)
        HStack(spacing: 16) {
            CategoryBadge(category: category)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.name)
                    Spacer()
                }
                .font(.callout.weight(.semibold))
                if let summary = finance.budget(for: category)?.summary {
                    Text(summary).foregroundStyle(Color.secondary)
                }
            }
            VStack(alignment: .trailing, spacing: 4) {
                CategoryVariation(category: category)
                    .scaleEffect(0.7)
                    .padding(.trailing, -6)
                if budgeted > .zero {
                    Text(budgeted.formatted(.brl)).font(.callout.weight(.semibold))
                }
                if spent > .zero {
                    Text(spent.formatted(.brl))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            .multilineTextAlignment(.trailing)
            .fixedSize()
            Image(systemName: "chevron.forward").foregroundStyle(.disabled)
        }
    }
}
