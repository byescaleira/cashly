import CashlyDomain
import CashlyWidgetUI
import SwiftUI
import WidgetKit

struct BillsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CashlyWidget.bills.kind, provider: SnapshotProvider()) { entry in
            SnapshotWidgetView(widget: .bills, entry: entry)
        }
        .configurationDisplayName("Upcoming Bills")
        .description("Pending bills by due date; tap one to open it in Cashly.")
        .supportedFamilies(CashlyWidget.bills.families)
    }
}

#Preview("Small", as: .systemSmall) {
    BillsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}

#Preview("Medium", as: .systemMedium) {
    BillsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
