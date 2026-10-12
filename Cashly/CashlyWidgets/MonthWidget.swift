import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cashly.month", provider: SnapshotProvider()) { entry in
            MonthView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "cashly://home"))
        }
        .configurationDisplayName("This Month")
        .description("Spent, planned and what is still available.")
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        #if os(iOS)
            [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
            [.systemSmall, .systemMedium]
        #endif
    }
}

private struct MonthView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            #if os(iOS)
            case .accessoryCircular:
                Gauge(value: snapshot.progress) {
                    Image(systemName: "creditcard")
                } currentValueLabel: {
                    Text(snapshot.progress.formatted(.percent.precision(.fractionLength(0))))
                }
                .gaugeStyle(.accessoryCircular)
            case .accessoryInline:
                Text("Available \(snapshot.money(snapshot.availableMinorUnits))")
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text("Available").font(.caption).foregroundStyle(.secondary)
                    Text(snapshot.money(snapshot.availableMinorUnits)).font(.headline)
                    Gauge(value: snapshot.progress) { EmptyView() }.gaugeStyle(.accessoryLinear)
                }
            #endif
            case .systemMedium:
                MediumMonth(snapshot: snapshot)
            default:
                SmallMonth(snapshot: snapshot)
            }
        } else {
            EmptyMonth()
        }
    }
}

private struct SmallMonth: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            Text("Available").font(.caption).foregroundStyle(.secondary)
            Text(snapshot.money(snapshot.availableMinorUnits))
                .font(.title2.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(snapshot.availableMinorUnits < 0 ? Color.negative : Color.primary)
            Spacer(minLength: 0)
            Gauge(value: snapshot.progress) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(snapshot.progress < 1 ? Color.accentColor : Color.negative)
            Text("\(snapshot.money(snapshot.spentMinorUnits)) of \(snapshot.money(snapshot.plannedMinorUnits))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct MediumMonth: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .top) {
                MonthFigure(title: "Spent", value: snapshot.money(snapshot.spentMinorUnits))
                Spacer()
                MonthFigure(title: "Planned", value: snapshot.money(snapshot.plannedMinorUnits))
                Spacer()
                MonthFigure(
                    title: "Available", value: snapshot.money(snapshot.availableMinorUnits),
                    color: snapshot.availableMinorUnits < 0 ? .negative : .positive)
            }
            Gauge(value: snapshot.progress) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(snapshot.progress < 1 ? Color.accentColor : Color.negative)
            Text("\(snapshot.progress.formatted(.percent.precision(.fractionLength(0)))) used")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MonthFigure: View {
    let title: LocalizedStringKey
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

struct EmptyMonth: View {
    var body: some View {
        VStack(spacing: .spaceXS) {
            Image(systemName: "creditcard").font(.title2).foregroundStyle(.secondary)
            Text("Open Cashly to see your month")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
