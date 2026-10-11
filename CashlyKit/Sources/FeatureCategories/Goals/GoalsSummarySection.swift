import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct GoalsSummarySection: View {
    @Environment(GoalsModel.self) private var goals

    var body: some View {
        let overview = goals.overview
        if !overview.items.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    AdaptiveStack(alignment: .center, spacing: 20) {
                        UsageRing(ratio: overview.ratio, color: color(for: overview.ratio))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(overview.remaining >= 0 ? "Disponível" : "Passou do planejado")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(abs(overview.remaining).formatted(.appCurrency))
                                .font(.title.weight(.bold))
                                .foregroundStyle(
                                    overview.remaining >= 0 ? Color.primary : .negative
                                )
                                .amountLine()
                            VStack(alignment: .leading, spacing: 2) {
                                Legend(
                                    color: color(for: overview.ratio), title: "Gasto",
                                    value: overview.spent)
                                Legend(
                                    color: .secondary.opacity(0.35), title: "Planejado",
                                    value: overview.planned)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        if let daily = overview.dailyAllowance, let days = overview.daysLeft {
                            Hint(
                                symbol: "calendar",
                                text:
                                    "Dá para gastar \(daily.formatted(.appCurrency)) por dia nos próximos \(days) dias."
                            )
                        }
                        if let projected = overview.projectedSpent {
                            Hint(
                                symbol: projected > overview.planned
                                    ? "exclamationmark.triangle" : "chart.line.uptrend.xyaxis",
                                text:
                                    "No ritmo atual, o mês fecha em \(projected.formatted(.appCurrency))."
                            )
                        }
                        if overview.unbudgeted > 0 {
                            Hint(
                                symbol: "tray",
                                text:
                                    "\(overview.unbudgeted.formatted(.appCurrency)) foram gastos em categorias sem orçamento."
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Resumo do mês").sectionTitle()
            }
        }
    }

    private func color(for ratio: Double) -> Color {
        ratio > 1 ? .negative : ratio >= 0.8 ? .warning : .positive
    }
}

private struct UsageRing: View {
    let ratio: Double
    let color: Color
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 104

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(ratio, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if ratio > 1 {
                Circle()
                    .trim(from: 0, to: min(ratio - 1, 1))
                    .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text(ratio.formatted(.percent.precision(.fractionLength(0))))
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText(value: ratio))
                Text("usado").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .frame(width: min(size, 112), height: min(size, 112))
        .padding(7)
        .animation(.smooth, value: ratio)
        .accessibilityElement(children: .combine)
    }
}

private struct Legend: View {
    let color: Color
    let title: LocalizedStringKey
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).foregroundStyle(.secondary)
            Text(value.formatted(.appCurrency)).fontWeight(.semibold)
        }
        .font(.footnote)
        .amountLine()
    }
}

private struct Hint: View {
    let symbol: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.footnote).foregroundStyle(.secondary)
        } icon: {
            Image(systemName: symbol).font(.footnote).foregroundStyle(.tint)
        }
    }
}
