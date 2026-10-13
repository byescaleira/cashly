import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.month", provider: SnapshotProvider()) { entry in
            MonthView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "cashly://home"))
        }
        .configurationDisplayName("This Month")
        .description("Spent, planned and what is still available.")
        .supportedFamilies(monthFamilies)
    }
}

struct BudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.focus", provider: SnapshotProvider()) { entry in
            MonthView(entry: entry.focused)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "cashly://budgets"))
        }
        .configurationDisplayName("One Budget")
        .description("Follows the budget you pick in Cashly › Settings › Widgets.")
        .supportedFamilies(monthFamilies)
    }
}

private var monthFamilies: [WidgetFamily] {
    #if os(iOS)
        [
            .systemSmall, .systemMedium, .systemLarge, .accessoryCircular,
            .accessoryRectangular, .accessoryInline,
        ]
    #else
        [.systemSmall, .systemMedium, .systemLarge]
    #endif
}

private struct MonthView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let figures = snapshot.figures(entry.category)
            if entry.category != nil, figures.line == nil {
                FocusEmpty()
            } else {
                switch family {
                #if os(iOS)
                case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                    LockScreenMonth(figures: figures, family: family)
                #endif
                case .systemMedium:
                    MediumMonth(figures: figures)
                case .systemLarge:
                    LargeMonth(figures: figures)
                default:
                    SmallMonth(figures: figures)
                }
            }
        } else {
            EmptyMonth()
        }
    }
}

private struct FocusEmpty: View {
    var body: some View {
        VStack(spacing: .spaceXS) {
            SymbolBadge("square.grid.2x2", color: .secondary, size: .badgeM)
            Text("Pick a budget in Cashly › Settings › Widgets")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct SmallMonth: View {
    let figures: MonthFigures

    var body: some View {
        let snapshot = figures.snapshot
        VStack(alignment: .leading, spacing: .spaceXS) {
            WidgetTitle(snapshot: snapshot, ratio: figures.ratio)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                WidgetLabel("Spent")
                Text(snapshot.money(figures.spent))
                    .font(.widgetAmount)
                    .fontDesign(.rounded)
                    .foregroundStyle(figures.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(snapshot.money(figures.planned))
                    .font(.widgetSecondary)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let line = figures.line {
                    Tag(line.categoryName.uppercased(), color: .primary)
                } else {
                    WidgetLabel("Total planned")
                }
            }
            Spacer(minLength: 0)
            RemainingRow(figures: figures)
        }
    }
}

private struct RemainingRow: View {
    let figures: MonthFigures
    var font: Font = .widgetValue

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            WidgetLabel("Remaining")
            HStack {
                Text(figures.snapshot.money(figures.remaining))
                    .font(font)
                    .foregroundStyle(figures.color)
                Spacer(minLength: 0)
                Text((1 - figures.ratio).percentLabel).font(font)
            }
            .lineLimit(1)
            UsageBar(ratio: figures.ratio)
        }
    }
}

private struct SpendHeader: View {
    @Environment(\.widgetFamily) private var family
    let figures: MonthFigures

    var body: some View {
        let snapshot = figures.snapshot
        HStack(alignment: .top, spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .space2XS) {
                WidgetTitle(snapshot: snapshot, ratio: figures.ratio)
                WidgetLabel("Total planned")
                Text(snapshot.money(figures.planned))
                    .font(.secondary(for: family))
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let line = figures.line {
                    Tag(line.categoryName.uppercased(), color: .primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: .space2XS) {
                HStack(spacing: .spaceXS) {
                    WidgetLabel("Spent")
                    Spacer(minLength: 0)
                    if figures.line == nil {
                        Tag("\(snapshot.transactionCount)", color: figures.color)
                    }
                }
                Text(snapshot.money(figures.spent))
                    .font(.amount(for: family))
                    .fontDesign(.rounded)
                    .foregroundStyle(figures.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(figures.ratio.percentLabel)
                    .font(.secondary(for: family))
                    .foregroundStyle(.secondary)
                UsageBar(ratio: figures.ratio)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MediumMonth: View {
    let figures: MonthFigures

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            SpendHeader(figures: figures)
            Spacer(minLength: 0)
            CategoryChart(snapshot: figures.snapshot, ratio: figures.ratio, height: 72)
        }
    }
}

private struct LargeMonth: View {
    let figures: MonthFigures

    var body: some View {
        let budgets = figures.snapshot.budgets.sorted { $0.plannedMinorUnits > $1.plannedMinorUnits }
        VStack(alignment: .leading, spacing: .spaceM) {
            SpendHeader(figures: figures)
            RemainingRow(figures: figures, font: .widgetSecondary)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: .spaceL), GridItem(.flexible())],
                spacing: .spaceM
            ) {
                ForEach(budgets.prefix(8), id: \.id) { BudgetCell(line: $0) }
            }
            CategoryChart(snapshot: figures.snapshot, ratio: figures.ratio, height: 120)
                .frame(maxHeight: .infinity)
        }
    }
}

#if os(iOS)
    private struct LockScreenMonth: View {
        let figures: MonthFigures
        let family: WidgetFamily

        var body: some View {
            let snapshot = figures.snapshot
            switch family {
            case .accessoryCircular:
                Gauge(value: min(max(figures.ratio, 0), 1)) {
                    Image(systemName: figures.line?.icon ?? "creditcard")
                } currentValueLabel: {
                    Text((1 - figures.ratio).percentLabel).bold()
                }
                .gaugeStyle(.accessoryCircular)
            case .accessoryInline:
                Text("\(snapshot.money(figures.remaining)) left")
            default:
                VStack(alignment: .leading, spacing: 0) {
                    Text(figures.line?.categoryName.uppercased() ?? snapshot.monthName.uppercased())
                        .font(.footnote)
                    Spacer(minLength: 0)
                    Text(snapshot.money(figures.remaining))
                        .font(.system(size: 25, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer(minLength: 0)
                    HStack(spacing: .spaceS) {
                        Gauge(value: min(max(figures.ratio, 0), 1)) { EmptyView() }
                            .gaugeStyle(.accessoryLinear)
                        Text((1 - figures.ratio).percentLabel).font(.footnote)
                    }
                }
            }
        }
    }
#endif

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
    MonthWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
