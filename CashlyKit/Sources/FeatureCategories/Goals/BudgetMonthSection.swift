import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetMonthSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(\.appTint) private var appTint

    var body: some View {
        let overview = goals.overview
        if goals.hasBudgets {
            Section {
                PaceRow(overview: overview)
                FiguresRow(overview: overview)
                if let daily = overview.dailyAllowance, let days = overview.daysLeft {
                    SummaryRow(
                        symbol: "calendar", color: .positive, title: "You can spend",
                        detail: "over the next \(days) days",
                        value: "\(daily.formatted(.appCurrency)) per day", valueColor: .positive)
                } else if let days = overview.daysLeft {
                    SummaryRow(
                        symbol: "hand.raised.fill", color: .negative,
                        title: "Nothing left to spend",
                        detail: "\(days) days left in the month", value: nil, valueColor: .negative
                    )
                }
                if overview.unbudgeted > 0 {
                    SummaryRow(
                        symbol: "questionmark.folder", color: .secondary, title: "Outside budgets",
                        detail: "spent in categories without a budget",
                        value: "\(overview.unbudgeted.formatted(.appCurrency))",
                        valueColor: .primary)
                }
            } header: {
                VStack(spacing: .spaceS) {
                    Chip(goals.periodTitle.uppercased(), color: appTint, shape: .capsule)
                    Text(overview.remainingAmount.formatted(.appCurrency))
                        .font(.amountHero)
                        .foregroundStyle(overview.amountColor)
                        .contentTransition(.numericText(value: overview.remainingAmount))
                        .amountLine()
                    Text(overview.headline).font(.subheadline).foregroundStyle(.secondary)
                }
                .textCase(nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spaceL)
                .accessibilityElement(children: .combine)
            } footer: {
                EstimatesNotice()
            }
        }
    }
}

private struct PaceRow: View {
    let overview: BudgetOverview

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text(overview.usageTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(overview.usageColor)
                Spacer()
                if let day = overview.dayTitle {
                    Text(day).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            PaceBar(
                ratio: overview.ratio, elapsed: overview.elapsedRatio, color: overview.usageColor)
            if let pace = overview.pace, let detail = overview.paceDetail {
                Label(pace.title, systemImage: pace.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(pace.color)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

private struct PaceBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let ratio: Double
    let elapsed: Double?
    let color: Color

    var body: some View {
        ProgressView(value: isFilled ? min(ratio, 1) : 0)
            .tint(color)
            .animation(reduceMotion ? nil : .smooth(duration: 1), value: isFilled)
            .animation(reduceMotion ? nil : .smooth, value: ratio)
            .overlay {
                if let elapsed {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color.primary.opacity(.opacityStrong))
                            .frame(width: .spaceHairline, height: .barHeight)
                            .position(
                                x: proxy.size.width * min(elapsed, 1), y: proxy.size.height / 2)
                    }
                }
            }
            .task { isFilled = true }
            .accessibilityHidden(true)
    }
}

private struct FiguresRow: View {
    let overview: BudgetOverview

    var body: some View {
        HStack(spacing: .spaceS) {
            FigureCell(caption: "Planned", amount: overview.planned, color: .primary)
            FigureCell(caption: "Spent", amount: overview.spent, color: .primary)
            FigureCell(
                caption: overview.remaining >= 0 ? "Remaining" : "Over",
                amount: overview.remainingAmount, color: overview.amountColor)
        }
        .padding(.vertical, .space2XS)
    }
}

private struct FigureCell: View {
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

private struct SummaryRow: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let value: LocalizedStringKey?
    let valueColor: Color

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(symbol, color: color, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(title).font(.rowTitle).frame(maxWidth: .infinity, alignment: .leading)
                    if let value {
                        Text(value)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(valueColor)
                            .amountLine()
                    }
                }
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension BudgetOverview {
    var amountColor: Color { remaining >= 0 ? .primary : .negative }
    var usageColor: Color { ratio > 1 ? .negative : ratio >= 0.8 ? .warning : .positive }
}

extension BudgetOverview.Pace {
    var color: Color {
        switch self {
        case .over: .negative
        case .fast: .warning
        case .steady, .slow: .positive
        }
    }
}
