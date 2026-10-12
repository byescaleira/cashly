import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TopSpendingSection: View {
    @Environment(DashboardModel.self) private var dashboard
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let items = dashboard.topSpending
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    Button {
                        open(.addTransaction(id: item.id), in: section)
                    } label: {
                        TopSpendingRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Maiores gastos").sectionTitle()
            } footer: {
                if let share = dashboard.topSpendingShare {
                    Text(
                        "Estes \(items.count) gastos somam \(share.formatted(.percent.precision(.fractionLength(0)))) das saídas do período."
                    )
                }
            }
        }
    }
}

private struct TopSpendingRow: View {
    let item: DashboardModel.TopSpending

    var body: some View {
        let color = Color(hex: item.color)
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2), in: .circle)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.summary).font(.headline).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(item.amount.formatted(.appCurrency))
                        .font(.headline)
                        .amountLine()
                }
                HStack(spacing: 8) {
                    Text(
                        "\(item.category) · \(item.date.formatted(.dateTime.day().month(.abbreviated)))"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(color)
                }
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: max(proxy.size.width * min(item.share, 1), 6))
                }
                .frame(height: 5)
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
