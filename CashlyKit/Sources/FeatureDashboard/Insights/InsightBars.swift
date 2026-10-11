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
                .foregroundStyle(bar.isCurrent ? appTint : Color.secondary.opacity(0.3))
                .clipShape(.rect(cornerRadius: 6))
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

struct InsightChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2), in: .rect(cornerRadius: 8))
    }
}

struct InsightHeadline: View {
    let caption: String
    let value: Double
    let color: Color
    var detail: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(caption).font(.subheadline).foregroundStyle(.secondary)
            Text(value.formatted(.appCurrency))
                .font(.largeTitle.weight(.black))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: value))
                .amountLine()
            if let detail {
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
