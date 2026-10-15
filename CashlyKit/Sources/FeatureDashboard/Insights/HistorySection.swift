import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct HistorySection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let history = insights.history {
            ProCurtainSection(.history) {
                Section {
                    VStack(spacing: .spaceS) {
                        FigureBlock(
                            caption: history.difference <= 0
                                ? String(appLocalized: "You spent less than usual")
                                : String(appLocalized: "You spent more than usual"),
                            amount: abs(history.difference),
                            color: history.difference <= 0 ? .positive : .negative,
                            detail: history.months == 1
                                ? String(
                                    appLocalized:
                                        "Compared with last month, up to day \(history.day).")
                                : String(
                                    appLocalized:
                                        "Compared with the average of the last \(history.months) months, up to day \(history.day)."
                                )
                        )
                        InsightBars(bars: history.bars)
                    }
                } header: {
                    Text("Compared with Other Months").sectionTitle()
                }
            } preview: {
                InsightBars(bars: history.bars)
            }
        }
    }
}

struct UnusualSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        let unusual = insights.unusual
        if !unusual.isEmpty {
            ProCurtainSection(.unusual) {
                Section {
                    ForEach(unusual) { UnusualRow(item: $0) }
                } header: {
                    Text("Out of the Ordinary").sectionTitle()
                } footer: {
                    Text(
                        "Spending so far compared with what usually goes out by this day of the month."
                    )
                }
            } preview: {
                VStack(spacing: .spaceM) {
                    ForEach(unusual.prefix(2)) { UnusualRow(item: $0) }
                }
            }
        }
    }
}

private struct UnusualRow: View {
    let item: InsightsModel.Unusual

    var body: some View {
        HStack(alignment: .center, spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.name).font(.headline)
                Text(item.reference)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: .space2XS) {
                Text(item.current.formatted(.appCurrency))
                    .font(.headline)
                    .amountLine()
                Chip(item.badge, color: .warning)
            }
        }
    }
}
