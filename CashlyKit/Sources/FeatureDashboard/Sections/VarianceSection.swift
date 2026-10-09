import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct VarianceSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        @Bindable var dashboard = dashboard
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            let comparison = dashboard.comparison
            Section {
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comparison.planned.formatted(.appCurrency))
                            .font(.title3.weight(.bold))
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: comparison.planned)
                        Text("Orçamento").font(.callout.weight(.semibold)).foregroundStyle(.info)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(comparison.spent.formatted(.appCurrency))
                            .font(.title3.weight(.bold))
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: comparison.spent)
                        HStack(spacing: 8) {
                            Text(comparison.ratio.formatted(.percent.precision(.fractionLength(0))))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.secondary)
                            Text("Gasto")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                ComparisonChart(data: dashboard.comparisonPoints)
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Planejado × gasto").sectionTitle()
                    SymbolPicker(
                        items: finance.categories, selection: $dashboard.comparedCategory,
                        icon: \.icon, color: { Color(hex: $0.color) }, name: \.name, bounces: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
