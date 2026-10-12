import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct BudgetsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.budgets", provider: SnapshotProvider()) { entry in
            BudgetsView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "cashly://budgets"))
        }
        .configurationDisplayName("Budgets")
        .description("How much is left in each budget this month.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct BudgetsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot, !snapshot.budgets.isEmpty {
            VStack(alignment: .leading, spacing: .spaceS) {
                ForEach(snapshot.budgets.prefix(family == .systemLarge ? 6 : 3), id: \.id) { line in
                    BudgetRow(line: line, snapshot: snapshot)
                }
                Spacer(minLength: 0)
            }
        } else if entry.snapshot == nil {
            EmptyMonth()
        } else {
            Text("No budgets this month").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct BudgetRow: View {
    let line: WidgetSnapshot.BudgetLine
    let snapshot: WidgetSnapshot

    var body: some View {
        let color = Color(hex: line.color)
        let ratio =
            line.plannedMinorUnits > 0
            ? min(Double(line.spentMinorUnits) / Double(line.plannedMinorUnits), 1) : 0
        HStack(spacing: .spaceS) {
            Image(systemName: line.icon).foregroundStyle(color).frame(width: .badgeS)
            VStack(alignment: .leading, spacing: .space2XS) {
                HStack {
                    Text(line.categoryName).font(.caption.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Text(
                        line.remainingMinorUnits >= 0
                            ? snapshot.money(line.remainingMinorUnits)
                            : "−" + snapshot.money(-line.remainingMinorUnits)
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(line.remainingMinorUnits >= 0 ? Color.secondary : Color.negative)
                }
                Gauge(value: ratio) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(line.remainingMinorUnits >= 0 ? color : Color.negative)
            }
        }
    }
}
