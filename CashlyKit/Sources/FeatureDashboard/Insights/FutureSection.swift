import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FutureSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let commitments = insights.commitments {
            Section {
                VStack(spacing: 8) {
                    InsightHeadline(
                        caption: "Já comprometido em parcelas", value: commitments.total,
                        color: .primary)
                    InsightBars(bars: commitments.bars)
                }
                LabeledContent(
                    "No próximo mês", value: commitments.nextMonth.formatted(.appCurrency))
            } header: {
                Text("Próximos meses").sectionTitle()
            } footer: {
                Text("Parcelas e contas futuras que você já registrou.")
            }
        }
    }
}
