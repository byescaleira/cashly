import Foundation

extension WebSnapshot {
    public struct Day: Codable, Equatable, Sendable {
        public let date: String
        public let spent: Double
    }

    public enum Outcome: String, Codable, Sendable {
        case under, onPlan, over
    }

    public struct Forecast: Codable, Equatable, Sendable {
        public let spent: Double
        public let available: Double
        public let outcome: Outcome
        public let planned: Double
    }

    public struct CategorySpending: Codable, Equatable, Sendable {
        public let name: String
        public let symbol: String
        public let color: String
        public let spent: Double
        public let share: Double
    }

    public struct TagSpending: Codable, Equatable, Sendable {
        public let name: String
        public let spent: Double
        public let count: Int
    }

    public struct MonthTotals: Codable, Equatable, Sendable {
        public let month: String
        public let planned: Double
        public let spent: Double
        public let income: Double
    }

    public struct Savings: Codable, Equatable, Sendable {
        public let saved: Double
        public let rate: Double
        public let averageRate: Double
    }

    public struct Score: Codable, Equatable, Sendable {
        public let value: Int
        public let max: Int
        public let label: String
        public let detail: String
    }

    public struct Journey: Codable, Equatable, Sendable {
        public let level: Int
        public let levelTitle: String
        public let progress: Double
        public let streak: Int
        public let challenge: ActiveChallenge?
    }

    public struct ActiveChallenge: Codable, Equatable, Sendable {
        public let title: String
        public let progress: Double
        public let endsOn: String
    }

    public static let categoryLimit = 8
    public static let tagLimit = 8
    public static let historyLength = 6
    public static let otherSymbol = "ellipsis"
    public static let otherColor = "brown"
}
