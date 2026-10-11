import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct GoalsSummarySection: View {
    @Environment(GoalsModel.self) private var goals

    var body: some View {
        let overview = goals.overview
        if !overview.items.isEmpty {
            Section {
                VStack(spacing: 16) {
                    UsageGauge(overview: overview, color: color(for: overview.ratio))
                    Divider()
                    VStack(spacing: 2) {
                        Text(overview.remaining >= 0 ? "Disponível" : "Acima do planejado")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text(
                            "\(Text(abs(overview.remaining).formatted(.appCurrency)).foregroundStyle(overview.remaining >= 0 ? Color.primary : .negative)) / \(Text(overview.planned.formatted(.appCurrency)).foregroundStyle(.secondary))"
                        )
                        .font(.title3.weight(.bold))
                        .amountLine()
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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

private struct UsageGauge: View {
    let overview: BudgetOverview
    let color: Color
    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize: CGFloat = 200
    private let sweep = 2.0 / 3.0
    private let lineWidth: CGFloat = 16

    private var size: CGFloat { min(scaledSize, 240) }
    private var progress: Double { min(max(overview.ratio, 0), 1) * sweep }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                arc(to: sweep).stroke(.quaternary, style: stroke)
                arc(to: progress).stroke(color, style: stroke)
                VStack(spacing: 0) {
                    Text("Gasto")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(overview.spent.formatted(.appCurrency))
                        .font(.title.weight(.bold))
                        .contentTransition(.numericText(value: overview.spent))
                        .amountLine()
                    Text(
                        "\(overview.ratio.formatted(.percent.precision(.fractionLength(0)))) · \(overview.status)"
                    )
                    .font(.footnote.weight(.bold))
                    .textCase(.uppercase)
                    .contentTransition(.numericText(value: overview.ratio))
                    .foregroundStyle(color)
                }
                .padding(.horizontal, lineWidth * 2)
            }
            .frame(width: size, height: size)
            .frame(height: size * 0.75 + lineWidth / 2, alignment: .top)
            HStack {
                Text(0.0.formatted(.percent))
                Spacer()
                Text(1.0.formatted(.percent))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: size)
        }
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: overview.ratio)
        .accessibilityElement(children: .combine)
    }

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    private func arc(to end: Double) -> some Shape {
        Circle()
            .inset(by: lineWidth / 2)
            .trim(from: 0, to: end)
            .rotation(.degrees(150))
    }
}

private struct Hint: View {
    let symbol: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        } icon: {
            Image(systemName: symbol).font(.subheadline).foregroundStyle(.tint)
        }
    }
}
