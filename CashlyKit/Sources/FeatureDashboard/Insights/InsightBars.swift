import CashlyDesignSystem
import Charts
import SwiftUI

struct InsightBars: View {
    @Environment(\.appTint) private var appTint
    let bars: [InsightsModel.Bar]
    var axis: LocalizedStringKey = "Month"
    @ScaledMetric(relativeTo: .caption) private var height = 110.0

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value(axis, bar.label), y: .value("Amount", bar.value), width: .ratio(0.55)
            )
            .foregroundStyle(bar.isCurrent ? appTint : Color.secondary.opacity(.opacitySoft))
            .clipShape(.rect(cornerRadius: .radiusS))
            .accessibilityLabel(bar.label)
            .accessibilityValue(bar.value.formatted(.appCurrency))
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel().font(.caption.weight(.semibold))
            }
        }
        .frame(height: height)
    }
}
