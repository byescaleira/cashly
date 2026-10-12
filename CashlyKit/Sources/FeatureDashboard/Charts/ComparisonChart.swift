import CashlyDesignSystem
import Charts
import SwiftUI

struct ComparisonChart: View {
    @Environment(\.appTint) private var appTint

    let data: [ComparisonPoint]
    var visibleCount: Double = 4.5
    @ScaledMetric(relativeTo: .caption) private var height = 120.0

    var body: some View {
        Chart(data) { point in
            bar(point, value: point.planned, series: "budget")
            bar(point, value: point.spent, series: "transaction")
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartXAxis {
            AxisMarks(values: data.map(\.id)) { value in
                AxisValueLabel {
                    if let id = value.as(String.self) {
                        Text(verbatim: data.first { $0.id == id }?.label ?? "")
                    }
                }
            }
        }
        .chartPlotStyle { $0.padding(.vertical, .spaceM) }
        .chartYScale(domain: 0...((data.map { max($0.planned, $0.spent) }.max() ?? 0) + 10))
        .chartLegend(.hidden)
        .chartScrolling(visible: visibleCount, count: data.count)
        .chartForegroundStyleScale(["budget": Color.companion, "transaction": appTint])
        .frame(height: height)
        .padding(.bottom, .spaceL)
    }

    private func bar(_ point: ComparisonPoint, value: Double, series: String) -> some ChartContent {
        BarMark(
            x: .value("Category", point.id), y: .value("Amount", value), width: 20,
            stacking: .standard
        )
        .foregroundStyle(by: .value("Series", series))
        .position(by: .value("Position", series))
    }
}
