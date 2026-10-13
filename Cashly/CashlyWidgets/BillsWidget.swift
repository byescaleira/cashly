import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct BillsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.bills", provider: SnapshotProvider()) { entry in
            BillsView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Upcoming Bills")
        .description("Pending bills by due date; tap one to open it in Cashly.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct BillsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let limit = family == .systemLarge ? 8 : 3
            VStack(alignment: .leading, spacing: .spaceXS) {
                HStack {
                    WidgetTitle(snapshot: snapshot, ratio: snapshot.figures(nil).ratio)
                    Spacer(minLength: 0)
                    Tag("\(snapshot.bills.count)", color: .accentColor)
                }
                WidgetLabel("Pending")
                Text(snapshot.money(snapshot.pendingMinorUnits))
                    .font(.widgetAmount)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                if snapshot.bills.isEmpty {
                    HStack(spacing: .spaceXS) {
                        SymbolBadge("checkmark", color: .positive, size: 18)
                        Text("No pending bills").font(.widgetRow).foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(Array(snapshot.bills.prefix(limit).enumerated()), id: \.element.id) {
                        index, bill in
                        if index > 0 { Divider().padding(.leading, 18 + .spaceXS) }
                        Link(
                            destination: URL(string: "cashly://transactions/\(bill.id)")
                                ?? URL(filePath: "/")
                        ) {
                            BillRow(bill: bill, snapshot: snapshot, compact: family == .systemSmall)
                        }
                    }
                }
            }
        } else {
            EmptyMonth()
        }
    }
}

private struct BillRow: View {
    let bill: WidgetSnapshot.Bill
    let snapshot: WidgetSnapshot
    let compact: Bool

    var body: some View {
        let overdue = bill.date < Calendar.current.startOfDay(for: .now)
        HStack(spacing: .spaceXS) {
            SymbolBadge(bill.icon, color: Color(hex: bill.color), size: 18)
            Text(bill.summary).font(.widgetRow).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            if !compact {
                Text(bill.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.widgetRow)
                    .foregroundStyle(overdue ? Color.negative : Color.secondary)
                    .lineLimit(1)
            }
            Text(snapshot.money(bill.amountMinorUnits))
                .font(.widgetRow.weight(.semibold))
                .foregroundStyle(overdue && compact ? Color.negative : Color.primary)
                .lineLimit(1)
        }
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
