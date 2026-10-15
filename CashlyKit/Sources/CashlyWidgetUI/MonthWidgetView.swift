import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct MonthWidgetView: View {
    let snapshot: WidgetSnapshot?
    let size: WidgetSize
    let isFocused: Bool

    var body: some View {
        if let snapshot {
            if !isFocused {
                MonthLayout(figures: MonthFigures(snapshot: snapshot, line: nil), size: size)
            } else if let line = snapshot.focusLine {
                MonthLayout(figures: MonthFigures(snapshot: snapshot, line: line), size: size)
            } else if let name = snapshot.focusCategoryName {
                WidgetMessage(
                    symbol: "scope", text: Text("\(name) has no budget this month"), size: size)
            } else {
                WidgetMessage.noBudgets(size)
            }
        } else {
            WidgetMessage.empty(size)
        }
    }
}

private struct MonthLayout: View {
    let figures: MonthFigures
    let size: WidgetSize

    var body: some View {
        switch size {
        case .circular, .rectangular, .inline: LockScreenMonth(figures: figures, size: size)
        case .medium: MediumMonth(figures: figures)
        case .large: LargeMonth(figures: figures)
        case .small: SmallMonth(figures: figures)
        }
    }
}

private struct SmallMonth: View {
    let figures: MonthFigures

    var body: some View {
        let snapshot = figures.snapshot
        VStack(alignment: .leading, spacing: .spaceXS) {
            WidgetTitle(snapshot: snapshot, ratio: figures.ratio, line: figures.line)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                WidgetLabel("Spent")
                Text(verbatim: snapshot.money(figures.spent))
                    .font(.widgetAmount)
                    .fontDesign(.rounded)
                    .foregroundStyle(figures.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: snapshot.money(figures.planned))
                    .font(.widgetSecondary)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                WidgetLabel(figures.line == nil ? "Total planned" : "Planned")
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
                Text(verbatim: figures.snapshot.money(figures.remaining))
                    .font(font)
                    .foregroundStyle(figures.color)
                Spacer(minLength: 0)
                Text(verbatim: (1 - figures.ratio).percentLabel).font(font)
            }
            .lineLimit(1)
            UsageBar(ratio: figures.ratio)
        }
    }
}

private struct SpendHeader: View {
    let figures: MonthFigures
    let size: WidgetSize

    var body: some View {
        let snapshot = figures.snapshot
        HStack(alignment: .top, spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .space2XS) {
                WidgetTitle(snapshot: snapshot, ratio: figures.ratio, line: figures.line)
                WidgetLabel(figures.line == nil ? "Total planned" : "Planned")
                Text(verbatim: snapshot.money(figures.planned))
                    .font(.widgetSecondary(size))
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: .space2XS) {
                HStack(spacing: .spaceXS) {
                    WidgetLabel("Spent")
                    Spacer(minLength: 0)
                    if figures.line == nil {
                        WidgetTag("\(snapshot.transactionCount)", color: figures.color)
                    }
                }
                Text(verbatim: snapshot.money(figures.spent))
                    .font(.widgetAmount(size))
                    .fontDesign(.rounded)
                    .foregroundStyle(figures.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: figures.ratio.percentLabel)
                    .font(.widgetSecondary(size))
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
            SpendHeader(figures: figures, size: .medium)
            Spacer(minLength: 0)
            CategoryChart(
                snapshot: figures.snapshot, ratio: figures.ratio, focus: figures.line?.id,
                height: 72)
        }
    }
}

private struct LargeMonth: View {
    let figures: MonthFigures

    var body: some View {
        let budgets = figures.snapshot.budgets.sorted {
            $0.plannedMinorUnits > $1.plannedMinorUnits
        }
        VStack(alignment: .leading, spacing: .spaceM) {
            SpendHeader(figures: figures, size: .large)
            RemainingRow(figures: figures, font: .widgetSecondary)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: .spaceL), GridItem(.flexible())],
                spacing: .spaceM
            ) {
                ForEach(budgets.prefix(8), id: \.id) { BudgetCell(line: $0) }
            }
            CategoryChart(
                snapshot: figures.snapshot, ratio: figures.ratio, focus: figures.line?.id,
                height: 120
            )
            .frame(maxHeight: .infinity)
        }
    }
}

private struct LockScreenMonth: View {
    let figures: MonthFigures
    let size: WidgetSize

    var body: some View {
        let snapshot = figures.snapshot
        switch size {
        case .circular:
            VStack(spacing: .spaceHairline) {
                Image(systemName: figures.line?.icon ?? "creditcard").font(.caption.weight(.bold))
                Text(verbatim: (1 - figures.ratio).percentLabel)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                UsageBar(ratio: figures.ratio, height: 4, color: .primary)
                    .frame(width: 34)
            }
        case .inline:
            Label {
                Text("\(snapshot.money(figures.remaining)) left")
            } icon: {
                Image(systemName: figures.line?.icon ?? "creditcard")
            }
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: figures.line?.categoryName ?? snapshot.monthName)
                    .font(.footnote)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: snapshot.money(figures.remaining))
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                HStack(spacing: .spaceS) {
                    UsageBar(ratio: figures.ratio, height: 5, color: .primary)
                    Text(verbatim: (1 - figures.ratio).percentLabel).font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
