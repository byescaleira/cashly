import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TransactionTotalSection: View {
    @Environment(TransactionListModel.self) private var list
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if list.isShowingTotals {
            let totals = list.totals
            Section {
                if totals.isMixed { TotalBreakdownRow(totals: totals) }
                if list.isFiltered {
                    ActiveFiltersRow()
                    Button("Clear Filters", systemImage: "eraser.line.dashed") {
                        list.clearFilters()
                    }
                }
            } header: {
                TotalHeader(totals: totals)
            } footer: {
                if list.isFilteredOut { Text("No transactions match these filters.") }
            }
            .animation(reduceMotion ? nil : .smooth, value: totals)
        }
    }
}

private struct TotalHeader: View {
    @Environment(TransactionListModel.self) private var list
    @Environment(\.appTint) private var appTint
    let totals: TransactionTotals

    var body: some View {
        VStack(spacing: .spaceS) {
            Chip(list.periodTitle.uppercased(), color: appTint, shape: .capsule)
            Text(totals.amount.formatted(.appCurrency))
                .font(.amountHero)
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText(value: totals.amount))
                .amountLine()
                .loading(list.isLoadingTotals)
            HStack(spacing: .spaceXS) {
                Text(totals.caption)
                Text(verbatim: "·")
                Text("\(totals.count) transactions")
                    .contentTransition(.numericText(value: Double(totals.count)))
            }
            .font(.subheadline)
            .foregroundStyle(Color.secondary)
            .loading(list.isLoadingTotals)
        }
        .textCase(nil)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceL)
        .accessibilityElement(children: .combine)
    }
}

private struct TotalBreakdownRow: View {
    let totals: TransactionTotals

    var body: some View {
        HStack(spacing: .spaceS) {
            TotalFigure(caption: "Spent", amount: totals.spent, color: .primary)
            TotalFigure(caption: "Received", amount: totals.received, color: .primary)
            TotalFigure(
                caption: "Balance", amount: totals.balance,
                color: totals.balance < 0 ? .negative : .positive)
        }
        .padding(.vertical, .space2XS)
    }
}

private struct TotalFigure: View {
    let caption: LocalizedStringKey
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: .spaceHairline) {
            Text(caption).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(amount.formatted(.appCurrency))
                .font(.callout.weight(.semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: amount))
                .amountLine()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ActiveFiltersRow: View {
    @Environment(TransactionListModel.self) private var list

    var body: some View {
        FlowLayout(spacing: .spaceS) {
            ForEach(list.activeFilters) { filter in
                Chip(filter.title, color: filter.color)
            }
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

extension ActiveFilter {
    fileprivate var color: Color {
        switch self {
        case .category(let category): Color(hex: category.color)
        case .tag(let tag): Color(hex: tag.color)
        case .status(let status): status.color
        case .participant: .companion
        }
    }
}
