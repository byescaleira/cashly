import SwiftUI

public enum Guide: String, CaseIterable, Identifiable, Sendable {
    case tour, importSpreadsheet, budgets, sharing

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tour: "Conheça o Cashly"
        case .importSpreadsheet: "Importar planilha"
        case .budgets: "Planejar o mês"
        case .sharing: "Dividir despesas"
        }
    }

    public var subtitle: String {
        switch self {
        case .tour: "As abas e o que cada uma mostra"
        case .importSpreadsheet: "Traga transações de outro app ou planilha"
        case .budgets: "Orçamentos por categoria e acompanhamento"
        case .sharing: "Participantes, divisão e quem deve a quem"
        }
    }

    public var systemImage: String {
        switch self {
        case .tour: "sparkles"
        case .importSpreadsheet: "tablecells"
        case .budgets: "chart.pie.fill"
        case .sharing: "person.2.fill"
        }
    }
}

public struct ShowGuideAction {
    private let action: (Guide) -> Void

    public init(_ action: @escaping (Guide) -> Void) {
        self.action = action
    }

    public func callAsFunction(_ guide: Guide) {
        action(guide)
    }
}

extension EnvironmentValues {
    @Entry public var showGuide: ShowGuideAction?
}
