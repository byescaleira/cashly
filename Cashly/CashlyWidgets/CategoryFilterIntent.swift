import AppIntents
import CashlyDomain
import Foundation
import WidgetKit

struct CategoryFilterIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose a Category"
    static let description = IntentDescription("Shows one budget instead of the whole month.")

    @Parameter(title: "Category")
    var category: SnapshotCategoryEntity?

    init() {}
}

struct SnapshotCategoryEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static let defaultQuery = SnapshotCategoryQuery()

    let id: String
    let name: String
    let icon: String

    init(_ line: WidgetSnapshot.BudgetLine) {
        id = line.id
        name = line.categoryName
        icon = line.icon
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

struct SnapshotCategoryQuery: EntityQuery {
    init() {}

    func entities(for identifiers: [String]) async throws -> [SnapshotCategoryEntity] {
        (WidgetSnapshot.current()?.budgets ?? []).filter { identifiers.contains($0.id) }
            .map(SnapshotCategoryEntity.init)
    }

    func suggestedEntities() async throws -> [SnapshotCategoryEntity] {
        (WidgetSnapshot.current()?.budgets ?? []).map(SnapshotCategoryEntity.init)
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
            categoryID: configuration.category?.id)
    }

    func timeline(for configuration: CategoryFilterIntent, in context: Context) async
        -> Timeline<SnapshotEntry>
    {
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return Timeline(
            entries: [
                SnapshotEntry(date: .now, snapshot: .current(), categoryID: configuration.category?.id)
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
