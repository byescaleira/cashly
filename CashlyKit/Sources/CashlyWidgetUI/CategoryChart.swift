import CashlyDesignSystem
import CashlyDomain
import Charts
import SwiftUI

struct CategoryChart: View {
    let snapshot: WidgetSnapshot
    let ratio: Double
    var focus: String?
    var height: CGFloat = 80

    var body: some View {
        let lines = snapshot.budgets.sorted { $0.plannedMinorUnits > $1.plannedMinorUnits }
            .prefix(6)
        Chart {
            ForEach(Array(lines), id: \.id) { line in
                mark(line, value: line.plannedMinorUnits, series: "planned")
                mark(line, value: line.spentMinorUnits, series: "spent")
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(["planned": Color.retroOrange, "spent": Color.usage(ratio)])
        .frame(height: height)
    }

    private func mark(_ line: WidgetSnapshot.BudgetLine, value: Int64, series: String)
        -> some ChartContent
    {
        BarMark(
            x: .value("Category", String(line.categoryName.prefix(3)).capitalized + "."),
            y: .value("Amount", Double(value) / 100)
        )
        .foregroundStyle(by: .value("Series", series))
        .position(by: .value("Series", series))
        .opacity(focus == nil || focus == line.id ? 1 : .opacitySoft)
    }
}
