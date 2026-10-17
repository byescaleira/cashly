import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct ChangesSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        let changes = insights.changes
        if !changes.isEmpty {
            ProOnly {
                Section {
                    ForEach(changes) { ChangeRow(item: $0) }
                } header: {
                    Text("What Changed").sectionTitle()
                } footer: {
                    Text(
                        "Compared with what usually goes out by this day in recent months, and whether it came from buying more often or from paying more each time."
                    )
                }
            }
        }
    }
}

private struct ChangeRow: View {
    let item: InsightsModel.Change

    var body: some View {
        let color = item.isUp ? Color.negative : Color.positive
        AdaptiveRow(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.name).font(.rowTitle)
                Text(item.detail).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: .space2XS) {
                Text(item.amount)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: item.difference))
                    .amountLine()
                Chip(item.badge, color: color).fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct MerchantsSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        let merchants = insights.merchants
        if !merchants.isEmpty {
            ProOnly {
                Section {
                    ForEach(merchants) { MerchantRow(item: $0) }
                } header: {
                    Text("Repeat Purchases").sectionTitle()
                } footer: {
                    Text(
                        "Purchases without installments from the last three months with the same description, as a monthly average."
                    )
                }
            }
        }
    }
}

private struct MerchantRow: View {
    let item: InsightsModel.Merchant

    var body: some View {
        AdaptiveRow(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.name).font(.rowTitle)
                Text(item.detail).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.amount)
                .font(.callout.weight(.semibold))
                .contentTransition(.numericText(value: item.monthly))
                .amountLine()
        }
        .accessibilityElement(children: .combine)
    }
}

struct SmallPurchasesSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let small = insights.small {
            ProOnly {
                Section {
                    FigureBlock(
                        caption: small.caption, value: small.total.formatted(.appCurrency),
                        numeric: small.total, detail: small.detail)
                } header: {
                    Text("Small Purchases").sectionTitle()
                } footer: {
                    Text(
                        "Up to the amount you usually spend per purchase. Each one is small, but together they add up."
                    )
                }
            }
        }
    }
}

struct WeekdaySection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let weekdays = insights.weekdays {
            ProOnly {
                Section {
                    VStack(spacing: .spaceS) {
                        FigureBlock(
                            caption: weekdays.caption,
                            value: weekdays.average.formatted(.appCurrency),
                            numeric: weekdays.average, detail: weekdays.detail)
                        InsightBars(bars: weekdays.bars, axis: "Day")
                    }
                } header: {
                    Text("By Weekday").sectionTitle()
                } footer: {
                    Text(weekdays.footer)
                }
            }
        }
    }
}
