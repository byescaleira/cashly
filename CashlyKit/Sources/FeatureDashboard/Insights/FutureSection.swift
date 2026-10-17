import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FutureSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let commitments = insights.commitments {
            ProOnly {
                Section {
                    InsightBars(bars: commitments.bars)
                    LabeledContent(
                        "Next Month", value: commitments.nextMonth.formatted(.appCurrency))
                    ForEach(insights.endings) { LabeledContent($0.title, value: $0.amount) }
                } header: {
                    FigureHeader(title: "Coming Months", amount: commitments.total) {
                        Text("already committed to installments")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(
                        "Installments and future bills you've already recorded, and how much stops going out each month when installments end."
                    )
                }
            }
        }
    }
}
