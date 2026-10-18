import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FutureSection: View {
    @Environment(InsightsModel.self) private var insights
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let commitments = insights.commitments
        let nextMonth = insights.nextMonth
        if commitments != nil || nextMonth != nil {
            ProOnly {
                Section {
                    if let commitments {
                        InsightBars(bars: commitments.bars)
                        LabeledContent {
                            Text(commitments.nextMonth.formatted(.appCurrency))
                                .contentTransition(.numericText(value: commitments.nextMonth))
                                .amountLine()
                        } label: {
                            Text("Already committed next month")
                        }
                    }
                    if let nextMonth {
                        LabeledContent {
                            Text(nextMonth.amount)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText(value: nextMonth.total))
                                .amountLine()
                        } label: {
                            Text("Expected next month")
                            if let range = nextMonth.range { Text(range) }
                        }
                    }
                    ForEach(insights.endings) { LabeledContent($0.title, value: $0.amount) }
                } header: {
                    if let commitments {
                        FigureHeader(title: "Coming Months", amount: commitments.total) {
                            Text("already committed to installments")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Coming Months").sectionTitle()
                    }
                } footer: {
                    Text(insights.futureFooter)
                }
                .animation(reduceMotion ? nil : .smooth, value: nextMonth)
                .animation(reduceMotion ? nil : .smooth, value: commitments)
            }
        }
    }
}
