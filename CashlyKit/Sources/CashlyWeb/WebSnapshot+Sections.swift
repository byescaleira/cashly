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
        public let xp: Int?
        public let nextTitle: String?
        public let best: Int?
        public let freezes: Int?
        public let trackedToday: Bool?
        public let days: [StreakDay]?
        public let missions: Missions?
        public let achievements: Achievements?
    }

    public struct ActiveChallenge: Codable, Equatable, Sendable {
        public let title: String
        public let progress: Double
        public let endsOn: String
        public let xp: Int?
        public let detail: String?
    }

    public enum DayState: String, Codable, Sendable {
        case tracked, frozen, missed, pending
    }

    public struct StreakDay: Codable, Equatable, Sendable {
        public let date: String
        public let state: DayState
    }

    public struct Missions: Codable, Equatable, Sendable {
        public let renewsOn: String
        public let items: [MissionItem]
    }

    public struct MissionItem: Codable, Equatable, Sendable {
        public let title: String
        public let done: Int
        public let target: Int
        public let xp: Int
    }

    public enum Tier: String, Codable, Sendable {
        case bronze, silver, gold
    }

    public struct Achievements: Codable, Equatable, Sendable {
        public let unlocked: Int
        public let total: Int
        public let next: [NextAchievement]
        public let recent: [RecentAchievement]
    }

    public struct NextAchievement: Codable, Equatable, Sendable {
        public let title: String
        public let detail: String
        public let progress: Double
        public let done: Int?
        public let target: Int?
        public let xp: Int?
    }

    public struct RecentAchievement: Codable, Equatable, Sendable {
        public let title: String
        public let tier: Tier
        public let unlockedOn: String?
        public let xp: Int?
    }

    public static let categoryLimit = 8
    public static let tagLimit = 8
    public static let historyLength = 6
    public static let otherSymbol = "ellipsis"
    public static let otherColor = "brown"
    public static let recentAchievementCount = 3
}
