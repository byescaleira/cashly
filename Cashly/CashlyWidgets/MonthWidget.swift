import CashlyDomain
import CashlyWidgetUI
import SwiftUI
import WidgetKit

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CashlyWidget.month.kind, provider: SnapshotProvider()) { entry in
            SnapshotWidgetView(widget: .month, entry: entry)
        }
        .configurationDisplayName("This Month")
        .description("Spent, planned and what is still available.")
        .supportedFamilies(CashlyWidget.month.families)
    }
}

struct BudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CashlyWidget.budget.kind, provider: SnapshotProvider()) { entry in
            SnapshotWidgetView(widget: .budget, entry: entry)
        }
        .configurationDisplayName("One Budget")
        .description("Follows the budget you pick in Cashly › Settings › Widgets.")
        .supportedFamilies(CashlyWidget.budget.families)
    }
}

#Preview("Small", as: .systemSmall) {
    MonthWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}

#Preview("Budget", as: .systemSmall) {
    BudgetWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}

#Preview("Medium", as: .systemMedium) {
    MonthWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}

#Preview("Large", as: .systemLarge) {
    BudgetWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
