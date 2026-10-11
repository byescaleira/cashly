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
                        "Um número de 200 a 1.000 que compara o que você gastou com o que planejou para o período."
                )
            case 1:
                GuidePage(
                    title: "As faixas",
                    message: "Fica em 1.000 até 85% do planejado e cai aos poucos depois disso."
                ) {
                    GuideSymbol("gauge.with.dots.needle.67percent")
                } content: {
                    GuideFeatureList {
                        ForEach(BudgetHealth.Level.allCases.reversed(), id: \.self) { level in
                            GuideFeature(
                                "circle.fill",
                                title:
                                    "\(level.title) · \(level.scores.lowerBound.formatted())–\(level.scores.upperBound.formatted())",
                                detail: Self.rule(for: level), color: level.color)
                        }
                    }
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
                    title: "Como subir",
                    message:
                        "Pequenos ajustes ao longo do mês fazem mais diferença que um corte no fim."
                ) {
                    GuideSymbol("arrow.up.right.circle.fill")
                } content: {
                    GuideFeatureList {
                        GuideFeature(
                            "exclamationmark.triangle.fill",
                            title: "Olhe o que está perto do limite",
                            detail: "Em Metas, esses orçamentos aparecem primeiro.")
                        GuideFeature(
                            "slider.horizontal.3", title: "Planeje valores realistas",
                            detail: "Um orçamento que estoura todo mês ajuda menos que um ajustado."
                        )
                        GuideFeature(
                            "calendar", title: "Siga o valor por dia",
                            detail: "O Resumo do mês mostra quanto dá para gastar até o fim do mês."
                        )
                    }
                }
            }
        }
    }

    private static func rule(for level: BudgetHealth.Level) -> String {
        let limit = level.maximumUsage.formatted(.percent.precision(.fractionLength(0)))
        return switch level {
        case .healthy: "Gasto até \(limit) do planejado."
        case .overBudget, .atRisk: "Gasto até \(limit) do planejado."
        case .critical: "Acima disso; chega a 200 com o dobro do planejado."
        }
    }
}

private struct CurrentScore: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        let planned = finance.budgetsAmount
        let spent = finance.expensesAmount
        let health = finance.health
        if planned > 0 {
            let keepFull = planned * BudgetHealth.fullScoreUsage - spent
            let keepHealthy = planned * BudgetHealth.Level.healthy.maximumUsage - spent
            GuideValueList([
                GuideValue("Planejado", value: planned.formatted(.appCurrency)),
                GuideValue(
                    "Gasto",
                    value:
                        "\(spent.formatted(.appCurrency)) · \((spent / planned).formatted(.percent.precision(.fractionLength(0))))"
                ),
                GuideValue(
                    "Pontuação", value: "\(health.score.formatted()) · \(health.level.title)",
                    color: health.level.color),
            ])
            GuideFeatureList {
                if keepFull > 0 {
                    GuideFeature(
                        "checkmark.seal.fill",
                        title: "Mais \(keepFull.formatted(.appCurrency)) e continua 1.000",
                        color: .positive)
                }
                if keepHealthy > 0 {
                    GuideFeature(
                        "leaf.fill",
                        title: "Mais \(keepHealthy.formatted(.appCurrency)) e continua Saudável",
                        color: .positive)
                } else {
                    GuideFeature(
                        "exclamationmark.triangle.fill", title: "O gasto já passou do planejado",
                        detail:
                            "A pontuação volta a subir no próximo período ou com um orçamento maior.",
                        color: .warning)
                }
            }
        } else {
            GuideFeatureList {
                GuideFeature(
                    "chart.pie.fill", title: "Defina orçamentos em Metas",
                    detail: "Sem planejado não há com o que comparar.")
            }
        }
    }
}
