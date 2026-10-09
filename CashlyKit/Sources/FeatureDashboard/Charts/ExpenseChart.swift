import Charts
import SwiftUI

struct ExpenseChart: View {
    let data: [ChartPoint]
    var visibleCount: Double = 4.5

    var body: some View {
        Chart(data) { point in
            LineMark(x: .value("Item", point.id), y: .value("Valor", point.amount))
                .interpolationMethod(.monotone)
                .symbol(.circle)
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
        .chartYScale(domain: 0...((data.map(\.amount).max() ?? 0) + 10))
        .chartLegend(.hidden)
        .chartScrolling(visible: visibleCount, count: data.count)
        .frame(height: 120)
        .padding(.bottom, 16)
    }
}
