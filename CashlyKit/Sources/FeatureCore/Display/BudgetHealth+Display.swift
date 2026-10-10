import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension BudgetHealth.Level {
    public var title: String {
        switch self {
        case .critical: "Crítico"
        case .atRisk: "Em risco"
        case .overBudget: "Acima do orçamento"
        case .healthy: "Saudável"
        }
    }

    public var summary: String {
        switch self {
        case .critical:
            "Os gastos estão muito acima do planejado. É preciso agir agora para retomar o controle."
        case .atRisk:
            "Os gastos passaram do orçamento. Corte despesas não essenciais e acompanhe o caixa de perto para não piorar."
        case .overBudget:
            "Você ultrapassou o orçamento planejado. Ajuste os gastos e priorize o essencial para retomar o controle."
        case .healthy:
            "Ótimo! Você está dentro do orçamento e cuidando bem das finanças."
        }
    }

    public var color: Color {
        switch self {
        case .critical: .retroRust
        case .atRisk: .retroOrange
        case .overBudget: .retroMustard
        case .healthy: .retroOlive
        }
    }
}
