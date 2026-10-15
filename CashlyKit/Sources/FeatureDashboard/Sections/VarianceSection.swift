import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct VarianceSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            ProCurtainSection(.variance) {
                VarianceContent()
            } preview: {
                ComparisonChart(data: reports.comparisonPoints)
            }
        }
    }
}

private struct VarianceContent: View {
    @Environment(\.appTint) private var appTint
    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        @Bindable var reports = reports
        let comparison = reports.comparison
        Section {
            AdaptiveStack(alignment: .top, spacing: .spaceS) {
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text(comparison.planned.formatted(.appCurrency))
                        .font(.amountRow)
                        .amountLine()
                        .contentTransition(.numericText())
                        .animation(.bouncy, value: comparison.planned)
                    Text("Budget").font(.callout.weight(.semibold)).foregroundStyle(.info)
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
                                    .percent.precision(.fractionLength(0)).locale(.app))
                            )
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.secondary)
                        }
                        Text("Spent")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(appTint)
                    }
                }
            }
            ComparisonChart(data: reports.comparisonPoints)
        } header: {
            VStack(alignment: .leading, spacing: .spaceS) {
                Text("Planned × Spent").sectionTitle()
                SymbolPicker(
                    items: finance.categories, selection: $reports.comparedCategory,
                    icon: \.icon, color: { Color(hex: $0.color) }, name: \.name,
                    bounces: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
