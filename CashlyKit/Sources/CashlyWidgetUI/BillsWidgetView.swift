import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct BillsWidgetView: View {
    let snapshot: WidgetSnapshot?
    let size: WidgetSize

    var body: some View {
        if let snapshot {
            VStack(alignment: .leading, spacing: .spaceXS) {
                HStack {
                    WidgetTitle(snapshot: snapshot, ratio: snapshot.spentRatio)
                    Spacer(minLength: 0)
                    WidgetTag("\(snapshot.bills.count)", color: .retroOrange)
                }
                WidgetLabel("Pending")
                Text(verbatim: snapshot.money(snapshot.pendingMinorUnits))
                    .font(.widgetAmount)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                BillList(snapshot: snapshot, size: size)
            }
        } else {
            WidgetMessage.empty(size)
        }
    }
}

private struct BillList: View {
    let snapshot: WidgetSnapshot
    let size: WidgetSize

    var body: some View {
        if snapshot.bills.isEmpty {
            HStack(spacing: .spaceXS) {
                SymbolBadge("checkmark", color: .positive, size: 18)
                Text("No pending bills").font(.widgetRow).foregroundStyle(.secondary)
            }
        } else {
            let bills = Array(snapshot.bills.prefix(size == .large ? 8 : 3))
            ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                if index > 0 { Divider().padding(.leading, 18 + .spaceXS) }
                Link(destination: bill.url) {
                    BillRow(bill: bill, snapshot: snapshot, isCompact: size == .small)
                }
            }
        }
    }
}

private struct BillRow: View {
    let bill: WidgetSnapshot.Bill
    let snapshot: WidgetSnapshot
    let isCompact: Bool

    var body: some View {
        let isOverdue = bill.date < Calendar.current.startOfDay(for: .now)
        HStack(spacing: .spaceXS) {
            SymbolBadge(bill.icon, color: Color(hex: bill.color), size: 18)
            Text(verbatim: bill.summary).font(.widgetRow).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            if !isCompact {
                Text(
                    verbatim: bill.date.formatted(.dateTime.day().month(.abbreviated).locale(.app))
                )
                .font(.widgetRow)
                .foregroundStyle(isOverdue ? Color.negative : Color.secondary)
                .lineLimit(1)
            }
            Text(verbatim: snapshot.money(bill.amountMinorUnits))
                .font(.widgetRow.weight(.semibold))
                .foregroundStyle(isOverdue && isCompact ? Color.negative : Color.primary)
                .lineLimit(1)
        }
    }
}

extension WidgetSnapshot {
    var spentRatio: Double {
        plannedMinorUnits > 0 ? Double(spentMinorUnits) / Double(plannedMinorUnits) : 0
    }
}

extension WidgetSnapshot.Bill {
    var url: URL {
        URL(string: "cashly://transactions/\(id)") ?? URL(filePath: "/")
    }
}
