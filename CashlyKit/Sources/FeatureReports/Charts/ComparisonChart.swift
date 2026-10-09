import Charts
import SwiftUI

struct ComparisonChart: View {
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
        .chartPlotStyle { $0.padding(.vertical, 10) }
        .chartYScale(domain: 0...((data.map { max($0.planned, $0.spent) }.max() ?? 0) + 10))
        .chartLegend(.hidden)
        .chartScrolling(visible: visibleCount, count: data.count)
        .chartForegroundStyleScale(["budget": Color.blue, "transaction": Color.accentColor])
        .frame(height: height)
        .padding(.bottom, 16)
    }

    private func bar(_ point: ComparisonPoint, value: Double, series: String) -> some ChartContent {
        BarMark(
            x: .value("Categoria", point.id), y: .value("Valor", value), width: 20,
            stacking: .standard
        )
        .foregroundStyle(by: .value("Série", series))
        .position(by: .value("Posição", series))
    }
}
