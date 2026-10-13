import AppIntents
import CashlyDomain
import Foundation
import WidgetKit

struct CategoryFilterIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose a Category"
    static let description = IntentDescription("Shows one budget instead of the whole month.")

    @Parameter(title: "Category", optionsProvider: CategoryOptions())
    var category: String?

    init() {}
}

struct CategoryOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        (WidgetSnapshot.current()?.budgets ?? []).map(\.categoryName)
    }
}

nonisolated struct MonthProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .sample)
    }

    func snapshot(for configuration: CategoryFilterIntent, in context: Context) async
        -> SnapshotEntry
    {
        SnapshotEntry(
            date: .now, snapshot: context.isPreview ? .sample : .current(),
            category: configuration.category)
    }

    func timeline(for configuration: CategoryFilterIntent, in context: Context) async
        -> Timeline<SnapshotEntry>
    {
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return Timeline(
            entries: [
                SnapshotEntry(date: .now, snapshot: .current(), category: configuration.category)
            ], policy: .after(refresh))
    }
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
