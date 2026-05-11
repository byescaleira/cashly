//
//  CashlyCompareChart.swift
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
        .accessibilityLabel(chartAccessibilityLabel)
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
        .accessibilityLabel(chartAccessibilityLabel)
    }
    
    private var chartAccessibilityLabel: String {
        guard !data.isEmpty else { return CashlyL10n.string("Empty chart") }
        let budget = CashlyL10n.string("Budget")
        let expense = CashlyL10n.string("Expense")
        return data.map {
            "\($0.0): \(budget) \($0.1.currency() ?? String(format: "%.2f", $0.1)), \(expense) \($0.2.currency() ?? String(format: "%.2f", $0.2))"
        }.joined(separator: ". ")
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
    
    #if DEBUG
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
    #endif
}

#if DEBUG
#Preview {
    CashlyCompareChart
        .mock
}
#endif
