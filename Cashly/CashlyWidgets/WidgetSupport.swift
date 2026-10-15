import CashlyDomain
import CashlyWidgetUI
import SwiftUI
import WidgetKit

nonisolated struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

nonisolated struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .sample : .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void)
    {
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(
            Timeline(entries: [SnapshotEntry(date: .now, snapshot: .current())], policy: .after(refresh))
        )
    }
}

extension WidgetSnapshot {
    nonisolated static func current() -> WidgetSnapshot? {
        try? WidgetSnapshotStore.shared?.read()
    }
}

struct SnapshotWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let widget: CashlyWidget
    let entry: SnapshotEntry

    var body: some View {
        let size = WidgetSize(family)
        CashlyWidgetView(widget, size: size, snapshot: entry.snapshot)
            .containerBackground(for: .widget) {
                if size == .circular {
                    AccessoryWidgetBackground()
                } else {
                    Rectangle().fill(.background)
                }
            }
            .widgetURL(widget.url)
    }
}

extension WidgetSize {
    init(_ family: WidgetFamily) {
        switch family {
        case .systemMedium: self = .medium
        case .systemLarge, .systemExtraLarge: self = .large
        #if os(iOS)
            case .accessoryCircular: self = .circular
            case .accessoryRectangular: self = .rectangular
            case .accessoryInline: self = .inline
        #endif
        default: self = .small
        }
    }
}

extension CashlyWidget {
    var families: [WidgetFamily] {
        sizes.compactMap(\.family)
    }
}

extension WidgetSize {
    var family: WidgetFamily? {
        switch self {
        case .small: .systemSmall
        case .medium: .systemMedium
        case .large: .systemLarge
        #if os(iOS)
            case .circular: .accessoryCircular
            case .rectangular: .accessoryRectangular
            case .inline: .accessoryInline
        #else
            case .circular, .rectangular, .inline: nil
        #endif
        }
    }
}
