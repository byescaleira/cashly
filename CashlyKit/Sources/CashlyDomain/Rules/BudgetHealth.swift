public struct BudgetHealth: Equatable, Sendable {
    public enum Level: CaseIterable, Sendable {
        case critical, atRisk, overBudget, healthy

        public var scores: ClosedRange<Int> {
            switch self {
            case .critical: 200...499
            case .atRisk: 500...699
            case .overBudget: 700...894
            case .healthy: 895...1000
            }
        }

        public var maximumUsage: Double { BudgetHealth.usage(for: scores.lowerBound) }

        public func progress(for score: Int) -> Double {
            let span = Double(scores.upperBound - scores.lowerBound)
            return min(max(Double(score - scores.lowerBound) / span, 0), 1)
        }
    }

    public static let maximumScore = 1000
    public static let fullScoreUsage = 0.85

    public static func usage(for score: Int) -> Double {
        fullScoreUsage + Double(maximumScore - score) / (800 / 1.15)
    }

    public let score: Int

    public init(usage: BudgetUsage) {
        let value =
            usage.ratio <= 0.85 ? 1000 : 1000 - (800 / 1.15) * (usage.ratio - 0.85)
        score = value.isFinite ? Int(min(max(value, 200), 1000)) : 200
    }

    public var level: Level {
        Level.allCases.first { $0.scores.contains(score) } ?? .critical
    }

    public var levelPosition: Double {
        Double(Level.allCases.firstIndex(of: level) ?? 0) + level.progress(for: score)
    }
}
