import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TopSpendingSection: View {
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        let items = dashboard.topSpending
        if let first = items.first {
            Section {
                VStack(alignment: .leading, spacing: .spaceM) {
                    ShareBar(items: items)
                    HeroTile(item: first)
                    ForEach(rows(of: Array(items.dropFirst())), id: \.first?.id) { row in
                        HStack(spacing: .spaceM) {
                            ForEach(row) { SmallTile(item: $0) }
                        }
                    }
                }
                .padding(.vertical, .spaceXS)
            } header: {
                Text("Top Spending").sectionTitle()
            }
        }
    }

    private func rows(of items: [DashboardModel.TopSpending]) -> [[DashboardModel.TopSpending]] {
        stride(from: 0, to: items.count, by: 2).map { Array(items[$0..<min($0 + 2, items.count)]) }
    }
}

private struct ShareBar: View {
    @Environment(DashboardModel.self) private var dashboard
    let items: [DashboardModel.TopSpending]

    var body: some View {
        let share = dashboard.topSpendingShare
        VStack(alignment: .leading, spacing: .spaceS) {
            GeometryReader { proxy in
                let width = proxy.size.width - CGFloat(items.count) * 2
                HStack(spacing: .spaceHairline) {
                    ForEach(items) { item in
                        Rectangle()
                            .fill(Color(hex: item.color))
                            .frame(width: max(width * item.share, 4))
                    }
                    Rectangle().fill(Color.secondary.opacity(.opacityTint))
                }
                .clipShape(.capsule)
            }
            .frame(height: 12)
            Text(
                share >= 0.995
                    ? "That's all the money out in the period."
                    : "Together, they add up to \(share.formatted(.percent.precision(.fractionLength(0)).locale(.app))) of the money out in the period."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HeroTile: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    let item: DashboardModel.TopSpending

    var body: some View {
        let color = Color(hex: item.color)
        Button {
            open(.addTransaction(id: item.id), in: section)
        } label: {
            VStack(alignment: .leading, spacing: .spaceM) {
                HStack {
                    SymbolBadge(
                        item.icon, color: Color(hex: item.color), size: .badgeM, style: .filled)
                    Spacer()
                    Text(item.share.formatted(.percent.precision(.fractionLength(0)).locale(.app)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, .spaceM)
                        .padding(.vertical, .space2XS)
                        .background(color.opacity(.opacityTint), in: .capsule)
                }
                Spacer(minLength: 0)
                Text(item.amount.formatted(.appCurrency))
                    .font(.amountHero)
                    .contentTransition(.numericText(value: item.amount))
                    .amountLine()
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(item.summary).font(.headline).lineLimit(1)
                    Text(item.detail).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(.spaceL)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [color.opacity(.opacityTint), color.opacity(.opacityFill)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing),
                in: .rect(cornerRadius: .radiusL)
            )
            .contentShape(.rect(cornerRadius: .radiusL))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Top expense: \(item.summary), \(item.amount.formatted(.appCurrency))")
    }
}

private struct SmallTile: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    let item: DashboardModel.TopSpending

    var body: some View {
        let color = Color(hex: item.color)
        Button {
            open(.addTransaction(id: item.id), in: section)
        } label: {
            VStack(alignment: .leading, spacing: .spaceS) {
                HStack {
                    SymbolBadge(
                        item.icon, color: Color(hex: item.color), size: .badgeS, style: .filled)
                    Spacer()
                    Text(item.share.formatted(.percent.precision(.fractionLength(0)).locale(.app)))
                        .font(.chipLabel)
                        .foregroundStyle(color)
                }
                Text(item.amount.formatted(.appCurrency))
                    .font(.amountRow)
                    .amountLine()
                Text(item.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.spaceM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(.opacityFill), in: .rect(cornerRadius: .radiusM))
            .contentShape(.rect(cornerRadius: .radiusM))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
