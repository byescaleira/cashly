import CashlyDomain
import Foundation

public struct GameProgress: Equatable, Sendable {
    public let xp: Int
    public let level: GameLevel
    public let streak: Streak
    public let achievements: [AchievementState]
    public let missions: [Mission]
    public let challenge: ChallengeState?
    public let completedChallenges: Int
    public let rerolls: Int
    public let challengeStartsThisMonth: Int

    public var canStartChallenge: Bool { challengeStartsThisMonth == 0 || rerolls > 0 }
}

public enum GameEngine {
    public static let blueScore = BudgetHealth.Level.healthy.scores.lowerBound
    public static let transactionXP = 10
    public static let dailyTransactionLimit = 10
    public static let trackingXP = 5
    public static let budgetXP = 30
    public static let blueMonthXP = 200
    public static let perfectMonthXP = 100
    public static let guideXP = 20

    public static func progress(_ snapshot: GameSnapshot) -> GameProgress {
        let streak = Streak(snapshot)
        let challenges = ChallengeState.all(in: snapshot)
        let completed = challenges.filter { $0.status == .completed }
        let closedMonths = monthsBefore(snapshot.ledger.currentMonth, in: snapshot)
        let scores = closedMonths.compactMap { month in
            snapshot.score(in: month).map { (month, $0) }
        }
        let blueMonths = scores.filter { $0.1 >= blueScore }.map(\.0)
        let perfectMonths = scores.filter { $0.1 == BudgetHealth.maximumScore }.count
        let base =
            transactionXP(snapshot) + snapshot.trackedDays.count * trackingXP
            + budgetXP(snapshot) + blueMonths.count * blueMonthXP + perfectMonths * perfectMonthXP
            + Set(snapshot.events(.guideCompleted).map(\.value)).count * guideXP
            + Mission.completedXP(in: snapshot) + completed.reduce(0) { $0 + $1.xp }
        let facts = AchievementFacts(
            snapshot: snapshot, bestStreak: streak.best, blueMonths: blueMonths,
            perfectMonths: perfectMonths, completedChallenges: completed.count,
            level: GameLevel(xp: base).number)
        let achievements = Achievement.allCases.map {
            AchievementState(achievement: $0, value: facts.value(of: $0))
        }
        let xp = base + achievements.filter(\.isUnlocked).reduce(0) { $0 + $1.achievement.xp }
        let current = challenges.last.flatMap { state -> ChallengeState? in
            if case .active = state.status { return state }
            return nil
        }
        let starts = Dictionary(
            grouping: snapshot.events(.challengeStarted), by: { YearMonth($0.date) }
        ).mapValues(\.count)
        let used = starts.values.reduce(0) { $0 + max($1 - 1, 0) }
        let credited = snapshot.events(.rerollsCredited).reduce(0) { $0 + $1.count }
        return GameProgress(
            xp: xp, level: GameLevel(xp: xp), streak: streak, achievements: achievements,
            missions: Mission.week(containing: snapshot.today, in: snapshot), challenge: current,
            completedChallenges: completed.count, rerolls: max(credited - used, 0),
            challengeStartsThisMonth: starts[YearMonth(snapshot.today)] ?? 0)
    }

    private static func transactionXP(_ snapshot: GameSnapshot) -> Int {
        Dictionary(grouping: snapshot.transactions, by: { snapshot.day($0.date) })
            .values.reduce(0) { $0 + min($1.count, dailyTransactionLimit) * transactionXP }
    }

    private static func budgetXP(_ snapshot: GameSnapshot) -> Int {
        Set(snapshot.ledger.budgets.map { "\($0.category.id)|\($0.month.rawValue)" }).count
            * budgetXP
    }

    private static func monthsBefore(_ current: YearMonth, in snapshot: GameSnapshot) -> [YearMonth]
    {
        let months = snapshot.ledger.budgets.map(\.month) + snapshot.ledger.postings.map(\.month)
        guard let first = months.min() else { return [] }
        return (0..<max(current.months(since: first), 0)).map { first.adding(months: $0) }
    }
}
