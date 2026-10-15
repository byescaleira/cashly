import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FutureSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let commitments = insights.commitments {
            ProCurtainSection(.future) {
                Section {
                    InsightBars(bars: commitments.bars)
                    LabeledContent(
                        "Next Month", value: commitments.nextMonth.formatted(.appCurrency))
                } header: {
                    FigureHeader(title: "Coming Months", amount: commitments.total) {
                        Text("already committed to installments")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Installments and future bills you've already recorded.")
                }
            } preview: {
                InsightBars(bars: commitments.bars)
            }
        }
    }
}
