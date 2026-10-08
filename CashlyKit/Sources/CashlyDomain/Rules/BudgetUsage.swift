public struct BudgetUsage: Equatable, Sendable {
    public enum Stage: CaseIterable, Sendable {
        case justStarted, onTrack, watchOut, almostSpent, overBudget
    }

    public let ratio: Double

    public init(ratio: Double) {
        self.ratio = ratio
    }

    public init(spent: Double, budgeted: Double) {
        ratio = spent / (budgeted > 0 ? budgeted : 1)
    }

    public init(spent: Money, budgeted: Money) {
        self.init(spent: spent.doubleValue, budgeted: budgeted.doubleValue)
    }

    public var stage: Stage {
        switch ratio {
        case ..<0.1: .justStarted
        case ..<0.5: .onTrack
        case ..<0.9: .watchOut
        case ..<1.0: .almostSpent
        default: .overBudget
        }
    }

    public var isWarning: Bool { ratio >= 0.8 }
}
