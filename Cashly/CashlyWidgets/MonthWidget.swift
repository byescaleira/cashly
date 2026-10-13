import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "cashly.month.budget", intent: CategoryFilterIntent.self, provider: MonthProvider()
        ) { entry in
            MonthView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "cashly://home"))
        }
        .configurationDisplayName("This Month")
        .description("Spent, planned and what is still available.")
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        #if os(iOS)
            [
                .systemSmall, .systemMedium, .systemLarge, .accessoryCircular,
                .accessoryRectangular, .accessoryInline,
            ]
        #else
            [.systemSmall, .systemMedium, .systemLarge]
        #endif
    }
}

private struct MonthView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let figures = snapshot.figures(entry.category)
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
        } else {
            EmptyMonth()
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
                    .font(.widgetTitle)
                    .fontDesign(.rounded)
                    .foregroundStyle(figures.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(snapshot.money(figures.planned))
                    .font(.widgetTitle)
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

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            WidgetLabel("Remaining")
            HStack {
                Text(figures.snapshot.money(figures.remaining))
                    .font(.widgetValue)
                    .foregroundStyle(figures.color)
                Spacer(minLength: 0)
                Text((1 - figures.ratio).percentLabel).font(.widgetValue)
            }
            .lineLimit(1)
            UsageBar(ratio: figures.ratio)
        }
    }
}

private struct SpendHeader: View {
    let figures: MonthFigures

    var body: some View {
        let snapshot = figures.snapshot
        HStack(alignment: .top, spacing: .spaceS) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                WidgetTitle(
                    snapshot: snapshot, ratio: figures.ratio, font: .system(size: 18, weight: .bold)
                )
                HStack(spacing: .spaceXS) {
                    Text(snapshot.money(figures.planned))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let line = figures.line {
                        Tag(line.categoryName.uppercased(), color: .primary)
                    }
                }
            }
            .frame(width: 130, alignment: .leading)
            VStack(spacing: .space2XS) {
                HStack(spacing: .spaceXS) {
                    if figures.line == nil {
                        Tag("\(snapshot.transactionCount)", color: figures.color)
                    }
                    Text(snapshot.money(figures.spent))
                        .font(.footnote.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Text(figures.ratio.percentLabel)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                UsageBar(ratio: figures.ratio)
            }
            .padding(.top, .space2XS)
        }
    }
}

private struct MediumMonth: View {
    let figures: MonthFigures

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            SpendHeader(figures: figures)
            CategoryChart(snapshot: figures.snapshot, ratio: figures.ratio)
        }
    }
}

private struct LargeMonth: View {
    let figures: MonthFigures

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            SpendHeader(figures: figures)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: .spaceM), GridItem(.flexible())],
                spacing: .spaceS
            ) {
                ForEach(figures.snapshot.budgets.prefix(6), id: \.id) { BudgetCell(line: $0) }
            }
            CategoryChart(snapshot: figures.snapshot, ratio: figures.ratio, height: 140)
            Spacer(minLength: 0)
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
    SnapshotEntry(date: .now, snapshot: .sample, category: "Transporte")
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
