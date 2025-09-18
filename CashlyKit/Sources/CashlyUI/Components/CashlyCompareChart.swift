//
//  CashlyCompareChart.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 17/09/25.
//

import SwiftUI
import Charts
import CashlyDomain

enum CashlyChartType {
    case line
    case bar
}

struct CashlyCompareChart: CashlyView {
    @Environment(\.theme) var theme
    
    let type: CashlyChartType
    let data: [(String, Double, Double)]
    let startItemsAmount: Double
    
    init(
        type: CashlyChartType = .line,
        startItemsAmount: Double = 4.5,
        data: [(String, Double, Double)]
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
            ForEach(data.indices, id: \.self) { index in
                let data = data[index]
                buildBarMark(x: data.0, y: data.1, id: "budget")
                buildBarMark(x: data.0, y: data.2, id: "transaction")
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartPlotStyle { $0.padding(.vertical, 10) }
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .chartForegroundStyleScale(
            [
                "budget": theme.color.info,
                "transaction": Color.accentColor
            ]
        )
        .frame(height: 120)
        .cashlyPadding(.bottom, .medium)
    }
    
    var lineChart: some View {
        Chart {
            ForEach(data.indices, id: \.self) { index in
                let data = data[index]
                buildLineMark(x: data.0, y: data.1, id: "budget")
                buildLineMark(x: data.0, y: data.2, id: "transaction")
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartPlotStyle { $0.padding(.vertical, 10) }
        .chartYScale(domain: getDomain())
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: startItemsAmount)
        .chartForegroundStyleScale(
            [
                "budget": theme.color.info,
                "transaction": Color.accentColor
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
        .interpolationMethod(.cardinal)
        .foregroundStyle(by: .value("x-style", id))
        .symbol(.circle)
    }
    
    func getDomain() -> ClosedRange<Double> {
        var min: Double = .infinity
        var max: Double = .zero
        
        for item in data {
            let minItem = item.1 < item.2 ? item.1 : item.2
            let maxItem = item.1 > item.2 ? item.1 : item.2
            
            if minItem < min { min = minItem }
            if maxItem > max { max = maxItem }
        }
        
        return .zero ... (max + 10)
    }
    
    @ViewBuilder
    static var mock: some View {
        let categories = CashlyDomain.Category.mocks
        let data: [(String, Double, Double)] = categories.map {
            return (
                $0.name,
                .random(in: 10 ... 30),
                .random(in: 10 ... 30)
            )
        }
        CashlyCompareChart(data: data)
    }
}

#Preview {
    CashlyCompareChart
        .mock
}
