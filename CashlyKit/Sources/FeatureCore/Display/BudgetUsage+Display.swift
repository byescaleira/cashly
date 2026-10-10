import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension BudgetUsage.Stage {
    public var title: String {
        switch self {
        case .justStarted: "Começando"
        case .onTrack: "No caminho"
        case .watchOut: "Atenção"
        case .almostSpent: "Quase no limite"
        case .overBudget: "Acima do orçamento"
        }
    }

    public var color: Color {
        switch self {
        case .justStarted, .onTrack: .retroOlive
        case .watchOut: .retroMustard
        case .almostSpent: .retroOrange
        case .overBudget: .retroRust
        }
    }

    public var level: Int {
        switch self {
        case .justStarted, .onTrack: 1
        case .watchOut: 2
        case .almostSpent: 3
        case .overBudget: 4
        }
    }

    public func dotColor(at index: Int) -> Color {
        guard index <= level else { return .secondary.opacity(0.2) }
        return [Color.retroOlive, .retroMustard, .retroOrange, .retroRust][index - 1]
    }
}
