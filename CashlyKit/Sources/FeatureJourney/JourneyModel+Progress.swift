import CashlyDomain
import CashlyGame
import Foundation

public struct StreakMilestone: Equatable, Sendable {
    public let target: Int
    public let remaining: Int
    public let progress: Double
}

public struct ChallengeOutlook: Equatable, Sendable {
    public enum Pace: Equatable, Sendable {
        case steady, fast, over
    }

    public let progress: Double
    public let daysLeft: Int
    public let elapsed: Double?
    public let pace: Pace?

    public var isUsage: Bool { elapsed != nil }
}

extension JourneyModel {
    public var rankSteps: Double {
        guard let level = progress?.level else { return 0 }
        guard level.xpForNextLevel > 0 else { return Double(GameLevel.rankLength) }
        return Double((level.number - 1) % GameLevel.rankLength) + level.progress
    }

    public var levelsToNextRank: Int? {
        guard let level = progress?.level, let next = level.nextRankLevel else { return nil }
        return next - level.number
    }

    public var streakMilestone: StreakMilestone? {
        guard let current = progress?.streak.current else { return nil }
        let targets = Achievement.allCases.filter { $0.group == .consistency }.map(\.target)
        guard let target = targets.sorted().first(where: { $0 > current }) else { return nil }
        return StreakMilestone(
            target: target, remaining: target - current,
            progress: Double(current) / Double(target))
    }

    public var missionsDone: Int {
        progress?.missions.filter(\.isCompleted).count ?? 0
    }

    public var daysUntilNewMissions: Int {
        var calendar = CashlyCalendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: now())
        guard let end = calendar.dateInterval(of: .weekOfYear, for: today)?.end else { return 0 }
        return calendar.dateComponents([.day], from: today, to: end).day ?? 0
    }

    public var challengeOutlook: ChallengeOutlook? {
        progress?.challenge.flatMap { ChallengeOutlook($0, today: now()) }
    }

    public var nextAchievements: [AchievementState] {
        progress?.nextAchievements ?? []
    }

    public var unlockedCount: Int {
        progress?.unlockedCount ?? 0
    }

    public var unlockedRatio: Double {
        let total = progress?.achievements.count ?? 0
        return total > 0 ? Double(unlockedCount) / Double(total) : 0
    }
}

extension ChallengeOutlook {
    static let slack = 0.1

    public init?(
        _ state: ChallengeState, today now: Date, calendar: Calendar = CashlyCalendar.current
    ) {
        guard case .active(let value) = state.status else { return nil }
        let today = calendar.startOfDay(for: now)
        let daysLeft = max(calendar.dateComponents([.day], from: today, to: state.end).day ?? 0, 1)
        let ratio = max(value, 0)
        guard state.challenge.kind.measuresUsage else {
            self.init(progress: min(ratio, 1), daysLeft: daysLeft, elapsed: nil, pace: nil)
            return
        }
        let total = max(
            calendar.dateComponents([.day], from: state.from, to: state.end).day ?? 1, 1)
        let done = calendar.dateComponents([.day], from: state.from, to: today).day ?? 0
        let elapsed = min(max((Double(done) + 1) / Double(total), 0), 1)
        let pace: Pace = ratio >= 1 ? .over : ratio > elapsed + Self.slack ? .fast : .steady
        self.init(progress: min(ratio, 1), daysLeft: daysLeft, elapsed: elapsed, pace: pace)
    }
}

extension AchievementState {
    public var isStarted: Bool {
        !isUnlocked && !achievement.isSecret && achievement.target > 1 && value > 0
    }
}
