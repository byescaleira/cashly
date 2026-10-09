import CashlyDomain
import SwiftUI

extension BudgetUsage.Stage {
    public var title: String {
        switch self {
        case .justStarted: "Just started"
        case .onTrack: "On track"
        case .watchOut: "Watch out"
        case .almostSpent: "Almost spent"
        case .overBudget: "Over budget"
        }
    }

    public var color: Color {
        switch self {
        case .justStarted, .onTrack: .green
        case .watchOut: .yellow
        case .almostSpent: .orange
        case .overBudget: .red
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
        return [Color.green, .yellow, .orange, .red][index - 1]
    }
}
