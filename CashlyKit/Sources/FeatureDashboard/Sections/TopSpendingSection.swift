import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TopSpendingSection: View {
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        let items = dashboard.topSpending
        if let first = items.first {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ShareBar(items: items)
                    HeroTile(item: first)
                    ForEach(rows(of: Array(items.dropFirst())), id: \.first?.id) { row in
                        HStack(spacing: 10) {
                            ForEach(row) { SmallTile(item: $0) }
                        }
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text("Maiores gastos").sectionTitle()
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
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                let width = proxy.size.width - CGFloat(items.count) * 2
                HStack(spacing: 2) {
                    ForEach(items) { item in
                        Rectangle()
                            .fill(Color(hex: item.color))
                            .frame(width: max(width * item.share, 4))
                    }
                    Rectangle().fill(Color.secondary.opacity(0.2))
                }
                .clipShape(.capsule)
            }
            .frame(height: 12)
            Text(
                share >= 0.995
                    ? "São todas as saídas do período."
                    : "Juntos, somam \(share.formatted(.percent.precision(.fractionLength(0)))) das saídas do período."
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    CategoryBadge(item: item, size: 36)
                    Spacer()
                    Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2), in: .capsule)
                }
                Spacer(minLength: 0)
                Text(item.amount.formatted(.appCurrency))
                    .font(.largeTitle.weight(.black))
                    .contentTransition(.numericText(value: item.amount))
                    .amountLine()
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.summary).font(.headline).lineLimit(1)
                    Text(item.detail).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.28), color.opacity(0.08)], startPoint: .topLeading,
                    endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 20)
            )
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Maior gasto: \(item.summary), \(item.amount.formatted(.appCurrency))")
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CategoryBadge(item: item, size: 28)
                    Spacer()
                    Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                }
                Text(item.amount.formatted(.appCurrency))
                    .font(.title3.weight(.bold))
                    .amountLine()
                Text(item.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12), in: .rect(cornerRadius: 16))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct CategoryBadge: View {
    let item: DashboardModel.TopSpending
    let size: CGFloat

    var body: some View {
        let color = Color(hex: item.color)
        Image(systemName: item.icon)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .circle)
    }
}
