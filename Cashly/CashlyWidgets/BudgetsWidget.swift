import CashlyDomain
import CashlyWidgetUI
import SwiftUI
import WidgetKit

struct BudgetsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CashlyWidget.budgets.kind, provider: SnapshotProvider()) {
            entry in
            SnapshotWidgetView(widget: .budgets, entry: entry)
        }
        .configurationDisplayName("Budgets")
        .description("How much is left in each budget this month.")
        .supportedFamilies(CashlyWidget.budgets.families)
    }
}

#Preview("Medium", as: .systemMedium) {
    BudgetsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}

#Preview("Large", as: .systemLarge) {
    BudgetsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
