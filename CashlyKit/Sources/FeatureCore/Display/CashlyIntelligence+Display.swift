import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension CashlyIntelligence {
    public var name: String {
        switch self {
        case .budgetValue: "Orçamento inteligente"
        case .categoryName: "Categorização automática"
        case .tagValue: "Previsão por tag"
        }
    }

    public var summary: String {
        switch self {
        case .budgetValue:
            "Estima o gasto mensal de cada categoria pela média de até seis meses registrados."
        case .categoryName:
            "Sugere a categoria a partir das palavras de transações já registradas."
        case .tagValue:
            "Prevê o gasto esperado de cada tag em um mês a partir do histórico."
        }
    }

    public var icon: String {
        switch self {
        case .budgetValue: "dollarsign.bank.building"
        case .categoryName: "swatchpalette"
        case .tagValue: "tag"
        }
    }

    public var color: Color {
        switch self {
        case .budgetValue: .retroDenim
        case .categoryName: .retroOlive
        case .tagValue: .retroOrange
        }
    }
}
