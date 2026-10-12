import CashlyDomain
import Foundation
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
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .sample : current))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void)
    {
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(
            Timeline(entries: [SnapshotEntry(date: .now, snapshot: current)], policy: .after(refresh))
        )
    }

    private var current: WidgetSnapshot? {
        try? WidgetSnapshotStore.shared?.read()
    }
}

extension WidgetSnapshot {
    nonisolated static let sample = WidgetSnapshot(
        userID: "sample", userName: "Ana", month: YearMonth(.now), currencyCode: "BRL",
        plannedMinorUnits: 420_000, spentMinorUnits: 268_500, incomeMinorUnits: 650_000,
        budgets: [
            BudgetLine(
                id: "market", categoryName: "Mercado", color: "C2602A", icon: "cart",
                plannedMinorUnits: 150_000, spentMinorUnits: 112_000),
            BudgetLine(
                id: "transport", categoryName: "Transporte", color: "3D5F86", icon: "car",
                plannedMinorUnits: 60_000, spentMinorUnits: 61_500),
            BudgetLine(
                id: "fun", categoryName: "Lazer", color: "2A7069", icon: "gamecontroller",
                plannedMinorUnits: 80_000, spentMinorUnits: 35_000),
        ],
        bills: [
            Bill(id: "light", summary: "Luz", amountMinorUnits: 18_900, date: .now.addingTimeInterval(86_400 * 2)),
            Bill(id: "rent", summary: "Aluguel", amountMinorUnits: 180_000, date: .now.addingTimeInterval(86_400 * 6)),
        ])

    nonisolated func money(_ minorUnits: Int64) -> String {
        (Decimal(minorUnits) / 100).formatted(.currency(code: currencyCode).precision(.fractionLength(0...2)))
    }

    nonisolated var progress: Double {
        plannedMinorUnits > 0 ? min(Double(spentMinorUnits) / Double(plannedMinorUnits), 1) : 0
    }
}
