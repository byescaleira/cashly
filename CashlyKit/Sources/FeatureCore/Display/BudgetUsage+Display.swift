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
}
