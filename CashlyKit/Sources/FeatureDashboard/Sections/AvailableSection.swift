import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct AvailableSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        let rows = dashboard.budgetRows
        if !rows.isEmpty {
            Section {
                ForEach(rows.prefix(dashboard.visibleBudgetCount)) { row in
                    BudgetRowView(row: row)
                }
            } header: {
                FigureHeader(
                    title: "Disponível", value: dashboard.totalAvailable,
                    color: dashboard.totalAvailable < 0 ? .negative : .primary
                ) {
                    let usage = dashboard.totalUsage
                    Text("de \(finance.budgetsAmount.formatted(.appCurrency)) planejado")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .amountLine()
                    Text(
                        "\(usage.ratio.formatted(.percent.precision(.fractionLength(0)))) usado · \(usage.stage.title)"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(usage.stage.color)
                }
            } footer: {
                if dashboard.hiddenBudgetCount > 0 {
                    Text("Mais \(dashboard.hiddenBudgetCount) categorias com orçamento em Metas.")
                }
            }
        }
    }
}

private struct BudgetRowView: View {
    let row: DashboardModel.BudgetRow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name).font(.headline)
                Spacer(minLength: 8)
                Text(row.summary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(row.usage.stage.color)
                    .amountLine()
            }
            ProgressView(value: min(max(row.usage.ratio, 0), 1))
                .tint(row.usage.stage.color)
            Text("de \(row.budgeted.formatted(.appCurrency))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
