import Foundation

public struct JourneySnapshot: Codable, Hashable, Sendable {
    public static let kind = "cashly.journey"
    public static let liveActivityKey = "cashly.journey.liveActivity"
    public static let riskHour = 18

    public enum Status: String, Codable, Hashable, Sendable {
        case active, paused, hidden
    }

    public enum Tint: String, Codable, Hashable, Sendable {
        case orange, olive, teal, denim, mustard, rust
    }

    public struct Level: Codable, Hashable, Sendable {
        public let number: Int
        public let title: String
        public let xpIntoLevel: Int
        public let xpForNextLevel: Int
        public let totalXP: Int

        public init(number: Int, title: String, xpIntoLevel: Int, xpForNextLevel: Int, totalXP: Int)
        {
            self.number = number
            self.title = title
            self.xpIntoLevel = xpIntoLevel
            self.xpForNextLevel = xpForNextLevel
            self.totalXP = totalXP
        }

        public var isMaximum: Bool { xpForNextLevel == 0 }
        public var xpToNext: Int { max(xpForNextLevel - xpIntoLevel, 0) }

        public var progress: Double {
            isMaximum ? 1 : min(max(Double(xpIntoLevel) / Double(xpForNextLevel), 0), 1)
        }
    }

    public struct Streak: Codable, Hashable, Sendable {
        public let current: Int
        public let best: Int
        public let freezes: Int
        public let isTodayTracked: Bool
        public let day: Date

        public init(current: Int, best: Int, freezes: Int, isTodayTracked: Bool, day: Date) {
            self.current = current
            self.best = best
            self.freezes = freezes
            self.isTodayTracked = isTodayTracked
            self.day = day
        }

        public func isDone(on date: Date, calendar: Calendar = .current) -> Bool {
            isTodayTracked && calendar.isDate(day, inSameDayAs: date)
        }
    }

    public struct Mission: Codable, Hashable, Sendable, Identifiable {
        public let id: String
        public let title: String
        public let symbol: String
        public let value: Int
        public let target: Int
        public let xp: Int

        public init(id: String, title: String, symbol: String, value: Int, target: Int, xp: Int) {
            self.id = id
            self.title = title
            self.symbol = symbol
            self.value = value
            self.target = target
            self.xp = xp
        }

        public var isCompleted: Bool { value >= target }
        public var progress: Double { target > 0 ? min(Double(value) / Double(target), 1) : 1 }
    }

    public struct Challenge: Codable, Hashable, Sendable, Identifiable {
        public enum Unit: String, Codable, Hashable, Sendable {
            case money, days, count, score
        }

        public enum Pace: String, Codable, Hashable, Sendable {
            case steady, fast, over
        }

        public enum Outcome: String, Codable, Hashable, Sendable {
            case active, completed, failed
        }

        public let id: String
        public let title: String
        public let detail: String
        public let symbol: String
        public let tint: Tint
        public let xp: Int
        public let measure: String
        public let value: Int64
        public let target: Int64
        public let unit: Unit
        public let progress: Double
        public let elapsed: Double?
        public let pace: Pace?
        public let paceTitle: String?
        public let starts: Date
        public let ends: Date
        public let outcome: Outcome

        public init(
            id: String, title: String, detail: String, symbol: String, tint: Tint, xp: Int,
            measure: String, value: Int64, target: Int64, unit: Unit, progress: Double,
            elapsed: Double?, pace: Pace?, paceTitle: String?, starts: Date, ends: Date,
            outcome: Outcome
        ) {
            self.id = id
            self.title = title
            self.detail = detail
            self.symbol = symbol
            self.tint = tint
            self.xp = xp
            self.measure = measure
            self.value = value
            self.target = target
            self.unit = unit
            self.progress = progress
            self.elapsed = elapsed
            self.pace = pace
            self.paceTitle = paceTitle
            self.starts = starts
            self.ends = ends
            self.outcome = outcome
        }

        public func daysLeft(at date: Date, calendar: Calendar = .current) -> Int {
            guard date < ends else { return 0 }
            let days = calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: date), to: ends
            ).day
            return max(days ?? 0, 1)
        }

        public var tone: Tint {
            switch pace {
            case .steady: .olive
            case .fast: .mustard
            case .over: .rust
            case nil: tint
            }
        }
    }

    public struct StreakRisk: Codable, Hashable, Sendable, Identifiable {
        public let current: Int
        public let freezes: Int
        public let deadline: Date

        public init(current: Int, freezes: Int, deadline: Date) {
            self.current = current
            self.freezes = freezes
            self.deadline = deadline
        }

        public var id: String { "streak@" + String(Int(deadline.timeIntervalSince1970)) }
    }

    public struct Achievement: Codable, Hashable, Sendable {
        public let title: String
        public let symbol: String
        public let value: Int
        public let target: Int
        public let xp: Int

        public init(title: String, symbol: String, value: Int, target: Int, xp: Int) {
            self.title = title
            self.symbol = symbol
            self.value = value
            self.target = target
            self.xp = xp
        }

        public var progress: Double { target > 0 ? min(Double(value) / Double(target), 1) : 1 }
    }

    public let userID: String
    public let status: Status
    public let currencyCode: String
    public let level: Level
    public let streak: Streak
    public let missions: [Mission]
    public let challenge: Challenge?
    public let lastChallenge: Challenge?
    public let nextAchievement: Achievement?

    public init(
        userID: String, status: Status, currencyCode: String, level: Level, streak: Streak,
        missions: [Mission], challenge: Challenge? = nil, lastChallenge: Challenge? = nil,
        nextAchievement: Achievement? = nil
    ) {
        self.userID = userID
        self.status = status
        self.currencyCode = currencyCode
        self.level = level
        self.streak = streak
        self.missions = missions
        self.challenge = challenge
        self.lastChallenge = lastChallenge
        self.nextAchievement = nextAchievement
    }

    public var missionsDone: Int { missions.filter(\.isCompleted).count }

    public func streakRisk(at date: Date, calendar: Calendar = .current) -> StreakRisk? {
        guard status == .active, streak.current > 0, !streak.isDone(on: date, calendar: calendar),
            calendar.component(.hour, from: date) >= Self.riskHour,
            let deadline = calendar.date(
                byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
        else { return nil }
        return StreakRisk(current: streak.current, freezes: streak.freezes, deadline: deadline)
    }

    public func challengeEndingToday(at date: Date, calendar: Calendar = .current) -> Challenge? {
        guard status == .active, let challenge, challenge.outcome == .active,
            date < challenge.ends,
            calendar.isDate(challenge.ends.addingTimeInterval(-1), inSameDayAs: date)
        else { return nil }
        return challenge
    }

    public func finishedChallenge(id: String) -> Challenge? {
        guard let lastChallenge, lastChallenge.id == id, lastChallenge.outcome != .active else {
            return nil
        }
        return lastChallenge
    }

    public static func isLiveActivityEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: liveActivityKey) as? Bool ?? true
    }
}
