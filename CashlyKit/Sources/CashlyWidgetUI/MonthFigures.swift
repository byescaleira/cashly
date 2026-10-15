import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct MonthFigures {
    let snapshot: WidgetSnapshot
    let line: WidgetSnapshot.BudgetLine?

    var spent: Int64 { line?.spentMinorUnits ?? snapshot.spentMinorUnits }
    var planned: Int64 { line?.plannedMinorUnits ?? snapshot.plannedMinorUnits }
    var remaining: Int64 { planned - spent }
    var ratio: Double { planned > 0 ? Double(spent) / Double(planned) : 0 }
    var color: Color { .usage(ratio) }
}

extension Color {
    public static func usage(_ ratio: Double) -> Color {
        ratio > 1 ? .negative : ratio >= 0.8 ? .warning : .positive
    }
}

extension Double {
    var percentLabel: String {
        formatted(.percent.precision(.fractionLength(0)).locale(.app))
    }
}
