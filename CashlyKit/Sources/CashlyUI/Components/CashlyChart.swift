//
//  CashlyChart.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 17/09/25.
//

import SwiftUI
import CashlyResource
import Charts
import CashlyDomain
#if DEBUG
import CashlyMock
#endif

struct CashlyChart: CashlyView {


    let type: CashlyChartType
    let data: [(String, Double)]
    let startItemsAmount: Double

    init(
        type: CashlyChartType = .bar,
        startItemsAmount: Double = 7.5,
        data: [(String, Double)]
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
            ForEach(data.indices, id: \.self) { index in
                let data = data[index]
                buildBarMark(x: data.0, y: data.1)
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartPlotStyle { $0.padding(.vertical, 10) }
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    var lineChart: some View {
        Chart {
            ForEach(data.indices, id: \.self) { index in
                let data = data[index]
                buildLineMark(x: data.0, y: data.1)
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartPlotStyle { $0.padding(.vertical, 10) }
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    private var chartAccessibilityLabel: String {
        guard !data.isEmpty else { return CashlyL10n.string("Empty chart") }
        let formatted = data.map { "\($0.0): \($0.1.currency() ?? String(format: "%.2f", $0.1))" }
            .joined(separator: ", ")
        return formatted
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
        .interpolationMethod(.cardinal)
        .symbol(.circle)
    }

    func getDomain() -> ClosedRange<Double> {
        var min: Double = .infinity
        var max: Double = .zero

        for item in data {
            if item.1 < min { min = item.1 }
            if item.1 > max { max = item.1 }
        }

        return .zero ... (max + 10)
    }

    #if DEBUG
    @ViewBuilder
    static var mock: some View {
        let categories = CashlyDomain.Category.mocks
        let data: [(String, Double)] = categories.map {
            return (
                $0.name.capitalized,
                .random(in: 10 ... 30)
            )
        }
        CashlyChart(data: data)
    }
    #endif
}

#if DEBUG
#Preview {
    CashlyChart
        .mock
}
#endif
