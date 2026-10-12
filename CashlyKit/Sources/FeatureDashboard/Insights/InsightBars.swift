import CashlyDesignSystem
import Charts
import SwiftUI

struct InsightBars: View {
    @Environment(\.appTint) private var appTint
    let bars: [InsightsModel.Bar]
    @ScaledMetric(relativeTo: .caption) private var height = 110.0

    var body: some View {
        Chart(bars) { bar in
            BarMark(x: .value("Mês", bar.label), y: .value("Valor", bar.value), width: .ratio(0.55))
                .foregroundStyle(bar.isCurrent ? appTint : Color.secondary.opacity(.opacitySoft))
                .clipShape(.rect(cornerRadius: .radiusS))
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel().font(.caption.weight(.semibold))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
    }
}
