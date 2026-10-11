import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreGuideScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    private let count = 4

    var body: some View {
        let isLast = index == count - 1
        GuideSheet(
            index: index, count: count, back: index > 0 ? { index -= 1 } : nil,
            primary: GuideAction(isLast ? "Entendi" : "Continuar") {
                if isLast { dismiss() } else { index += 1 }
            }
        ) {
            switch index {
            case 0:
                GuidePage(
                    .illustrationReview, title: "Pontuação de saúde",
                    message:
                        "Um número de 200 a 1.000 que compara o que você gastou com o que planejou para o período. Quanto mais o gasto passa do planejado, menor ela fica."
                )
            case 1:
                GuidePage(
                    title: "Como funciona",
                    message:
                        "Fica em 1.000 enquanto o gasto não passa de 85% do planejado. Depois disso, cai aos poucos."
                ) {
                    GuideSymbol("gauge.with.dots.needle.67percent")
                } content: {
                    LevelsTable()
                }
            case 2:
                GuidePage(
                    title: "Seu período agora",
                    message: "Com os orçamentos e gastos do filtro atual."
                ) {
                    GuideSymbol("person.crop.circle.badge.checkmark")
                } content: {
                    CurrentScore()
                }
            default:
                GuidePage(
                    title: "Como subir a pontuação",
                    message:
                        "Pequenos ajustes ao longo do mês fazem mais diferença que um corte no fim."
                ) {
                    GuideSymbol("arrow.up.right.circle.fill")
                } content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Tip(
                            symbol: "exclamationmark.triangle.fill",
                            text: "Em Metas, olhe primeiro os orçamentos “Perto do limite”.")
                        Tip(
                            symbol: "slider.horizontal.3",
                            text:
                                "Ajuste orçamentos que estouram todo mês: um planejado realista ajuda mais."
                        )
                        Tip(
                            symbol: "calendar",
                            text:
                                "Use o valor por dia do Resumo do mês para guiar os próximos gastos."
                        )
                    }
                    .padding(16)
                    .background(.subtleFill, in: .rect(cornerRadius: 20))
                }
            }
        }
    }
}

private struct LevelsTable: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(BudgetHealth.Level.allCases.reversed(), id: \.self) { level in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle().fill(level.color).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            "\(level.title) · \(level.scores.lowerBound.formatted())–\(level.scores.upperBound.formatted())"
                        )
                        .font(.subheadline.weight(.bold))
                        Text(rule(for: level)).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.subtleFill, in: .rect(cornerRadius: 20))
    }

    private func rule(for level: BudgetHealth.Level) -> String {
        let limit = level.maximumUsage.formatted(.percent.precision(.fractionLength(0)))
        return switch level {
        case .healthy: "Gasto até \(limit) do planejado; 1.000 até 85%."
        case .overBudget, .atRisk: "Gasto até \(limit) do planejado."
        case .critical: "Gasto acima disso; chega a 200 com o dobro do planejado."
        }
    }
}

private struct CurrentScore: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        let planned = finance.budgetsAmount
        let spent = finance.expensesAmount
        let health = finance.health
        VStack(alignment: .leading, spacing: 10) {
            if planned > 0 {
                Row(title: "Planejado", value: planned.formatted(.appCurrency))
                Row(
                    title: "Gasto",
                    value:
                        "\(spent.formatted(.appCurrency)) · \((spent / planned).formatted(.percent.precision(.fractionLength(0))))"
                )
                Row(
                    title: "Pontuação",
                    value: "\(health.score.formatted()) · \(health.level.title)",
                    color: health.level.color)
                Divider()
                let keepFull = planned * BudgetHealth.fullScoreUsage - spent
                let keepHealthy = planned * BudgetHealth.Level.healthy.maximumUsage - spent
                if keepFull > 0 {
                    Tip(
                        symbol: "checkmark.circle.fill",
                        text:
                            "Gastando até mais \(keepFull.formatted(.appCurrency)), a pontuação continua 1.000."
                    )
                }
                if keepHealthy > 0 {
                    Tip(
                        symbol: "leaf.fill",
                        text: "Até mais \(keepHealthy.formatted(.appCurrency)), continua Saudável.")
                } else {
                    Tip(
                        symbol: "exclamationmark.triangle.fill",
                        text:
                            "O gasto já passou do planejado; a pontuação volta a subir no próximo período ou com um orçamento maior."
                    )
                }
            } else {
                Tip(
                    symbol: "chart.pie.fill",
                    text: "Defina orçamentos em Metas para ter uma pontuação de verdade.")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.subtleFill, in: .rect(cornerRadius: 20))
    }
}

private struct Row: View {
    let title: LocalizedStringKey
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color).amountLine()
        }
    }
}

private struct Tip: View {
    let symbol: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.footnote)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.tint)
        }
    }
}
