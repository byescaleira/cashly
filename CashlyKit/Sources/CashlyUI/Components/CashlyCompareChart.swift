import CashlyDesignSystem
import CashlyDomain
import Charts
import FeatureCore
import Foundation
import SwiftUI

enum CashlyChartType {
    case line
    case bar
}

struct CashlyComparisonPoint: Identifiable {
    let id: String
    let label: String
    let planned: Double
    let spent: Double
}

struct CashlyCompareChart: View {

    let type: CashlyChartType
    let data: [CashlyComparisonPoint]
    let startItemsAmount: Double

    init(
        type: CashlyChartType = .line,
        startItemsAmount: Double = 4.5,
        data: [CashlyComparisonPoint]
    ) {
        self.type = type
        self.data = data
        self.startItemsAmount = startItemsAmount
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
                buildBarMark(x: point.id, y: point.planned, id: "budget")
                buildBarMark(x: point.id, y: point.spent, id: "transaction")
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
        .chartScrolling(visible: startItemsAmount, count: data.count)
        .chartForegroundStyleScale(
            [
                "budget": Color.blue,
                "transaction": Color.accentColor,
            ]
        )
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
    }

    var lineChart: some View {
        Chart {
            ForEach(data) { point in
                buildLineMark(x: point.id, y: point.planned, id: "budget")
                buildLineMark(x: point.id, y: point.spent, id: "transaction")
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
        .chartScrolling(visible: startItemsAmount, count: data.count)
        .chartForegroundStyleScale(
            [
                "budget": Color.blue,
                "transaction": Color.accentColor,
            ]
        )
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
    }

    func buildBarMark(x: String, y: Double, id: String) -> some ChartContent {
        BarMark(
            x: .value("x", x),
            y: .value("y", y),
            width: 20,
            stacking: .standard
        )
        .foregroundStyle(by: .value("x-style", id))
        .position(by: .value("x-position", id))
    }

    func buildLineMark(x: String, y: Double, id: String) -> some ChartContent {
        LineMark(
            x: .value("x", x),
            y: .value("y", y)
        )
        .interpolationMethod(.monotone)
        .foregroundStyle(by: .value("x-style", id))
        .symbol(.circle)
    }

    func getDomain() -> ClosedRange<Double> {
        var min: Double = .infinity
        var max: Double = .zero

        for item in data {
            let minItem = item.planned < item.spent ? item.planned : item.spent
            let maxItem = item.planned > item.spent ? item.planned : item.spent

            if minItem < min { min = minItem }
            if maxItem > max { max = maxItem }
        }

        return .zero...(max + 10)
    }

}
