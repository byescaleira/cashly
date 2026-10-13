import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct BudgetsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.budgets", provider: SnapshotProvider()) { entry in
            BudgetsView(entry: entry)
                .containerBackground(.background, for: .widget)
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
            let figures = snapshot.figures(nil)
            let over = snapshot.budgets.filter { $0.ratio > 1 }.count
            VStack(alignment: .leading, spacing: .spaceM) {
                HStack {
                    WidgetTitle(snapshot: snapshot, ratio: figures.ratio)
                    Spacer(minLength: 0)
                    Tag("\(over)/\(snapshot.budgets.count)", color: figures.color)
                }
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: .spaceM), GridItem(.flexible())],
                    spacing: .spaceS
                ) {
                    ForEach(snapshot.budgets.prefix(family == .systemLarge ? 10 : 4), id: \.id) {
                        BudgetCell(line: $0)
                    }
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
