import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct BillsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.bills", provider: SnapshotProvider()) { entry in
            BillsView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Bills")
        .description("Pending bills by due date; tap one to open it in Cashly.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct BillsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot, !snapshot.bills.isEmpty {
            VStack(alignment: .leading, spacing: .spaceS) {
                ForEach(snapshot.bills.prefix(family == .systemLarge ? 5 : 3), id: \.id) { bill in
                    Link(destination: URL(string: "cashly://transactions/\(bill.id)") ?? URL(filePath: "/")) {
                        BillRow(bill: bill, snapshot: snapshot)
                    }
                }
                Spacer(minLength: 0)
            }
        } else if entry.snapshot == nil {
            EmptyMonth()
        } else {
            VStack(spacing: .spaceXS) {
                Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(Color.positive)
                Text("No pending bills").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct BillRow: View {
    let bill: WidgetSnapshot.Bill
    let snapshot: WidgetSnapshot

    var body: some View {
        let overdue = bill.date < Calendar.current.startOfDay(for: .now)
        HStack(spacing: .spaceS) {
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(bill.summary).font(.caption.weight(.semibold)).lineLimit(1)
                Text(bill.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(overdue ? Color.negative : Color.secondary)
            }
            Spacer()
            Text(snapshot.money(bill.amountMinorUnits))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
}
