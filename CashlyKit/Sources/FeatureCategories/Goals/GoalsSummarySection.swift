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
                    HStack(alignment: .top) {
                        Metric(title: "Planejado", value: overview.planned, color: .primary)
                        Metric(title: "Gasto", value: overview.spent, color: .primary)
                        Metric(
                            title: overview.remaining >= 0 ? "Disponível" : "Passou",
                            value: abs(overview.remaining),
                            color: overview.remaining >= 0 ? .positive : .negative)
                    }
                    ProgressView(value: min(overview.ratio, 1))
                        .tint(color(for: overview.ratio))
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

private struct Metric: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(value.formatted(.appCurrency))
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
                .amountLine()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
