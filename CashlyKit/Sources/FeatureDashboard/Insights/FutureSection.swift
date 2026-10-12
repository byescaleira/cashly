import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FutureSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let commitments = insights.commitments {
            Section {
                InsightBars(bars: commitments.bars)
                LabeledContent(
                    "No próximo mês", value: commitments.nextMonth.formatted(.appCurrency))
            } header: {
                FigureHeader(title: "Próximos meses", amount: commitments.total) {
                    Text("já comprometidos em parcelas")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Parcelas e contas futuras que você já registrou.")
            }
        }
    }
}
