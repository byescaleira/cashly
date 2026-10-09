import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct CategoryBudgetsSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    let category: CashlyDomain.Category

    var body: some View {
        let budgets = finance.budgets(for: category)
        if !budgets.isEmpty {
            Section {
                ForEach(budgets) { budget in
                    Button {
                        open(.addBudget(id: budget.id, categoryID: nil, date: nil), in: section)
                    } label: {
                        BudgetRow(budget: budget)
                    }
                    .foregroundStyle(Color.primary)
                }
            } header: {
                Text("Orçamentos").sectionTitle()
            }
        }
    }
}

private struct BudgetRow: View {
    @Environment(FinanceModel.self) private var finance
    let budget: Budget

    var body: some View {
        HStack(spacing: 16) {
            AdaptiveStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.month.startDate.formatted(.dateTime.month(.wide).year()))
                        .font(.callout.weight(.semibold))
                    Text(
                        finance.usage(of: budget).ratio.formatted(
                            .percent.precision(.fractionLength(0))))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.money.doubleValue.formatted(.appCurrency)).font(
                        .callout.weight(.semibold))
                    Text(finance.expensesAmount(for: budget).formatted(.appCurrency))
                }
                .amountLine()
            }
            Image(systemName: "chevron.forward").foregroundStyle(.disabled)
        }
        .font(.callout)
    }
}
