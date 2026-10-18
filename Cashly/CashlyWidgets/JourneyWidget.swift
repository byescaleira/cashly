import CashlyDomain
import CashlyWidgetUI
import SwiftUI
import WidgetKit

nonisolated struct JourneyEntry: TimelineEntry {
    let date: Date
    let snapshot: JourneySnapshot?
}

nonisolated struct JourneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> JourneyEntry {
        JourneyEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (JourneyEntry) -> Void) {
        completion(JourneyEntry(date: .now, snapshot: context.isPreview ? .sample : .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JourneyEntry>) -> Void) {
        let snapshot = JourneySnapshot.current()
        let calendar = Calendar.current
        let tomorrow =
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        let entries = [
            JourneyEntry(date: .now, snapshot: snapshot),
            JourneyEntry(date: tomorrow, snapshot: snapshot),
        ]
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }
}

struct JourneyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: JourneySnapshot.kind, provider: JourneyProvider()) { entry in
            JourneyEntryView(entry: entry)
        }
        .configurationDisplayName("Journey")
        .description("Level, streak, weekly missions and your challenge.")
        .supportedFamilies(WidgetSize.supported.compactMap(\.family))
    }
}

private struct JourneyEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JourneyEntry

    var body: some View {
        let size = WidgetSize(family)
        JourneyWidgetView(snapshot: entry.snapshot, size: size, date: entry.date)
            .containerBackground(for: .widget) {
                if size == .circular {
                    AccessoryWidgetBackground()
                } else {
                    Rectangle().fill(.background)
                }
            }
            .widgetURL(URL(string: "cashly://journey"))
    }
}

extension JourneySnapshot {
    nonisolated static func current() -> JourneySnapshot? {
        try? JourneySnapshotStore.shared?.read()
    }
}

#Preview("Small", as: .systemSmall) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
}

#Preview("Medium", as: .systemMedium) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    JourneyEntry(date: .now, snapshot: .sample.with(status: .hidden))
}

#Preview("Large", as: .systemLarge) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    JourneyEntry(date: .now, snapshot: nil)
}

#if os(iOS)
    #Preview("Rectangular", as: .accessoryRectangular) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
        JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    }

    #Preview("Circular", as: .accessoryCircular) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
    }

    #Preview("Inline", as: .accessoryInline) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
    }
#endif
