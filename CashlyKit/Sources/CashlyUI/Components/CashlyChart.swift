import CashlyDesignSystem
import CashlyDomain
import Charts
import FeatureCore
import Foundation
import SwiftUI

struct CashlyChartPoint: Identifiable {
    let id: String
    let label: String
    let amount: Double
}

struct CashlyChart: View {

    let type: CashlyChartType
    let data: [CashlyChartPoint]
    let startItemsAmount: Double

    init(
        type: CashlyChartType = .bar,
        startItemsAmount: Double = 7.5,
        data: [CashlyChartPoint]
    ) {
        self.type = type
        self.startItemsAmount = startItemsAmount
        self.data = data
    }

    @ViewBuilder
    var body: some View {
        switch type {
        case .line: lineChart
        case .bar: barChart
        }
    }

    var barChart: some View {
        Chart {
            ForEach(data) { point in
                buildBarMark(x: point.id, y: point.amount)
            }
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
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
    }

    var lineChart: some View {
        Chart {
            ForEach(data) { point in
                buildLineMark(x: point.id, y: point.amount)
            }
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
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
    }

    func buildBarMark(x: String, y: Double) -> some ChartContent {
        BarMark(
            x: .value("x", x),
            y: .value("y", y),
            width: 18,
            stacking: .standard
        )
    }

    func buildLineMark(x: String, y: Double) -> some ChartContent {
        LineMark(
            x: .value("x", x),
            y: .value("y", y)
        )
        .interpolationMethod(.monotone)
        .symbol(.circle)
    }

    func getDomain() -> ClosedRange<Double> {
        var min: Double = .infinity
        var max: Double = .zero

        for item in data {
            if item.amount < min { min = item.amount }
            if item.amount > max { max = item.amount }
        }

        return .zero...(max + 10)
    }

}
