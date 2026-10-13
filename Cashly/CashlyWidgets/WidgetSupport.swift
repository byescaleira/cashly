import CashlyDesignSystem
import CashlyDomain
import Charts
import Foundation
import SwiftUI
import WidgetKit

nonisolated struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    var category: String?
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

extension SnapshotEntry {
    nonisolated var focused: SnapshotEntry {
        SnapshotEntry(date: date, snapshot: snapshot, category: snapshot?.focusCategory ?? "")
    }
}

extension WidgetSnapshot {
    nonisolated static func current() -> WidgetSnapshot? {
        try? WidgetSnapshotStore.shared?.read()
    }

    nonisolated func money(_ minorUnits: Int64) -> String {
        (Decimal(minorUnits) / 100).formatted(
            .currency(code: currencyCode).precision(.fractionLength(0...2)))
    }

    nonisolated var monthLabel: String {
        guard let date = yearMonth?.startDate else { return "" }
        return date.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    nonisolated var monthName: String {
        guard let date = yearMonth?.startDate else { return "" }
        return date.formatted(.dateTime.month(.wide).year()).capitalized
    }

    nonisolated func line(_ category: String?) -> BudgetLine? {
        budgets.first { $0.categoryName == category }
    }

    nonisolated func figures(_ category: String?) -> MonthFigures {
        MonthFigures(snapshot: self, line: line(category))
    }

    nonisolated var pendingMinorUnits: Int64 {
        bills.reduce(0) { $0 + $1.amountMinorUnits }
    }
}

nonisolated struct MonthFigures {
    let snapshot: WidgetSnapshot
    let line: WidgetSnapshot.BudgetLine?

    var spent: Int64 { line?.spentMinorUnits ?? snapshot.spentMinorUnits }
    var planned: Int64 { line?.plannedMinorUnits ?? snapshot.plannedMinorUnits }
    var remaining: Int64 { planned - spent }
    var ratio: Double { planned > 0 ? Double(spent) / Double(planned) : 0 }
    var color: Color { .usage(ratio) }
}

extension WidgetSnapshot.BudgetLine {
    nonisolated var ratio: Double {
        plannedMinorUnits > 0 ? Double(spentMinorUnits) / Double(plannedMinorUnits) : 0
    }
}

extension Color {
    nonisolated static func usage(_ ratio: Double) -> Color {
        ratio > 1 ? .negative : ratio >= 0.8 ? .warning : .positive
    }
}

extension Double {
    nonisolated var percentLabel: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}

extension Font {
    static let widgetTitle = Font.subheadline.weight(.bold)
    static let widgetAmount = Font.title2.weight(.bold)
    static let widgetSecondary = Font.headline

    static func amount(for family: WidgetFamily) -> Font {
        family == .systemLarge ? .largeTitle.weight(.bold) : family == .systemMedium ? .title.weight(.bold) : .widgetAmount
    }

    static func secondary(for family: WidgetFamily) -> Font {
        family == .systemSmall ? .widgetSecondary : .title3.weight(.semibold)
    }
    static let widgetLabel = Font.system(size: 8, weight: .bold)
    static let widgetValue = Font.system(size: 13, weight: .bold)
    static let widgetRow = Font.system(size: 10)
}

struct WidgetTitle: View {
    let snapshot: WidgetSnapshot
    let ratio: Double
    var font: Font = .widgetTitle

    var body: some View {
        HStack(spacing: .spaceXS) {
            Text("Cashly")
                .font(font)
                .fontDesign(.rounded)
                .lineLimit(1)
            Tag(snapshot.monthLabel, color: .usage(ratio))
        }
    }
}

struct Tag: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .spaceXS)
            .padding(.vertical, .spaceHairline)
            .background(color.opacity(.opacityTint), in: .rect(cornerRadius: .space2XS))
    }
}

struct WidgetLabel: View {
    let key: LocalizedStringKey

    init(_ key: LocalizedStringKey) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.widgetLabel)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .lineLimit(1)
    }
}

struct UsageBar: View {
    let ratio: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(Color.usage(ratio))
                    .frame(width: proxy.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: height)
    }
}

struct BudgetCell: View {
    let line: WidgetSnapshot.BudgetLine

    var body: some View {
        HStack(spacing: .spaceXS) {
            SymbolBadge(line.icon, color: Color(hex: line.color), size: 22)
            VStack(spacing: .space2XS) {
                HStack {
                    Text(line.categoryName).font(.caption2.weight(.bold)).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(line.ratio.percentLabel).font(.caption2).lineLimit(1)
                }
                UsageBar(ratio: line.ratio, height: 4)
            }
        }
    }
}

struct CategoryChart: View {
    let snapshot: WidgetSnapshot
    let ratio: Double
    var height: CGFloat = 80

    var body: some View {
        let lines = snapshot.budgets.sorted { $0.plannedMinorUnits > $1.plannedMinorUnits }
            .prefix(6)
        Chart {
            ForEach(Array(lines), id: \.id) { line in
                mark(line, value: line.plannedMinorUnits, series: "planned")
                mark(line, value: line.spentMinorUnits, series: "spent")
            }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(["planned": Color.retroOrange, "spent": Color.usage(ratio)])
        .frame(height: height)
    }

    private func mark(_ line: WidgetSnapshot.BudgetLine, value: Int64, series: String)
        -> some ChartContent
    {
        BarMark(
            x: .value("Category", String(line.categoryName.prefix(3)).capitalized + "."),
            y: .value("Amount", Double(value) / 100)
        )
        .foregroundStyle(by: .value("Series", series))
        .position(by: .value("Series", series))
    }
}

struct EmptyMonth: View {
    var body: some View {
        VStack(spacing: .spaceXS) {
            SymbolBadge("creditcard", color: .secondary, size: .badgeM)
            Text("Open Cashly to see your month")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

extension WidgetSnapshot {
    nonisolated static let sample = WidgetSnapshot(
        userID: "sample", userName: "Ana", month: YearMonth(.now), currencyCode: "BRL",
        plannedMinorUnits: 420_000, spentMinorUnits: 268_500, incomeMinorUnits: 650_000,
        transactionCount: 37, focusCategory: "Transporte",
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
            BudgetLine(
                id: "home", categoryName: "Casa", color: "74415F", icon: "house",
                plannedMinorUnits: 130_000, spentMinorUnits: 60_000),
        ],
        bills: [
            Bill(
                id: "light", summary: "Luz", amountMinorUnits: 18_900,
                date: .now.addingTimeInterval(86_400 * 2), icon: "bolt", color: "B8860B"),
            Bill(
                id: "rent", summary: "Aluguel", amountMinorUnits: 180_000,
                date: .now.addingTimeInterval(86_400 * 6), icon: "house", color: "74415F"),
            Bill(
                id: "gym", summary: "Academia", amountMinorUnits: 9_900,
                date: .now.addingTimeInterval(86_400 * 9), icon: "figure.run", color: "2A7069"),
        ])
}
