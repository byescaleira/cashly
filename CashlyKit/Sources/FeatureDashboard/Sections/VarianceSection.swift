import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct VarianceSection: View {
    @Environment(\.appTint) private var appTint

    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        @Bindable var reports = reports
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            let comparison = reports.comparison
            Section {
                AdaptiveStack(alignment: .top, spacing: .spaceS) {
                    VStack(alignment: .leading, spacing: .space2XS) {
                        Text(comparison.planned.formatted(.appCurrency))
                            .font(.amountRow)
                            .amountLine()
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: comparison.planned)
                        Text("Orçamento").font(.callout.weight(.semibold)).foregroundStyle(.info)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: .space2XS) {
                        Text(comparison.spent.formatted(.appCurrency))
                            .font(.amountRow)
                            .amountLine()
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: comparison.spent)
                        HStack(spacing: .spaceS) {
                            if comparison.planned > 0 {
                                Text(
                                    comparison.ratio.formatted(
                                        .percent.precision(.fractionLength(0)))
                                )
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.secondary)
                            }
                            Text("Gasto")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(appTint)
                        }
                    }
                }
                ComparisonChart(data: reports.comparisonPoints)
            } header: {
                VStack(alignment: .leading, spacing: .spaceS) {
                    Text("Planejado × gasto").sectionTitle()
                    SymbolPicker(
                        items: finance.categories, selection: $reports.comparedCategory,
                        icon: \.icon, color: { Color(hex: $0.color) }, name: \.name, bounces: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
