import CashlyDomain
import CashlyGame
import Foundation

extension WebSnapshot.Journey {
    init(_ progress: GameProgress, context: WebSnapshot.Context) {
        let streak = progress.streak
        self.init(
            level: progress.level.number, levelTitle: progress.level.title,
            progress: WebSnapshot.Month.rounded(progress.level.progress),
            streak: streak.current,
            challenge: progress.challenge.flatMap { WebSnapshot.ActiveChallenge($0) },
            xp: progress.xp, nextTitle: progress.level.nextRankLevel.map(GameLevel.title(for:)),
            best: streak.best, freezes: streak.freezes, trackedToday: streak.isTodayTracked,
            days: streak.week.map { WebSnapshot.StreakDay($0, today: context.today) },
            missions: WebSnapshot.Missions(progress.missions, today: context.today),
            achievements: WebSnapshot.Achievements(progress, context: context))
    }
}

extension WebSnapshot.ActiveChallenge {
    init?(_ state: ChallengeState) {
        guard case .active(let value) = state.status else { return nil }
        self.init(
            title: state.challenge.kind.title,
            progress: WebSnapshot.Month.rounded(min(max(value, 0), 1)),
            endsOn: WebDay.string(state.end.addingTimeInterval(-1)), xp: state.challenge.kind.xp,
            detail: state.caption)
    }
}

extension WebSnapshot.StreakDay {
    init(_ day: Streak.Day, today: Date) {
        let isToday = CashlyCalendar.current.isDate(day.date, inSameDayAs: today)
        let state: WebSnapshot.DayState =
            switch day.state {
            case .tracked: .tracked
            case .covered: .frozen
            case .missed: isToday ? .pending : .missed
            }
        self.init(date: WebDay.string(day.date), state: state)
    }
}

extension WebSnapshot.Missions {
    init?(_ missions: [Mission], today: Date) {
        guard !missions.isEmpty else { return nil }
        var calendar = CashlyCalendar.current
        calendar.firstWeekday = 2
        let end = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today
        self.init(
            renewsOn: WebDay.string(end),
            items: missions.map { mission in
                WebSnapshot.MissionItem(
                    title: mission.kind.title, done: min(mission.value, mission.kind.target),
                    target: mission.kind.target, xp: Mission.xp)
            })
    }
}

extension WebSnapshot.Achievements {
    init?(_ progress: GameProgress, context: WebSnapshot.Context) {
        guard !progress.achievements.isEmpty else { return nil }
        let guides = context.guides.count
        let unlocked = progress.achievements.filter(\.isUnlocked).map(\.achievement)
        let dated = unlocked.compactMap { achievement in
            context.unlocks[achievement].map { (achievement, $0) }
        }
        .sorted { $0.1 > $1.1 }
        let undated = unlocked.reversed().filter { context.unlocks[$0] == nil }
        let recent = (dated.map { ($0.0, Optional($0.1)) } + undated.map { ($0, nil) })
            .prefix(WebSnapshot.recentAchievementCount)
        self.init(
            unlocked: unlocked.count, total: progress.achievements.count,
            next: progress.nextAchievements.map { WebSnapshot.NextAchievement($0, guides: guides) },
            recent: recent.map { WebSnapshot.RecentAchievement($0.0, unlockedOn: $0.1) })
    }
}

extension WebSnapshot.NextAchievement {
    init(_ state: AchievementState, guides: Int) {
        let achievement = state.achievement
        let counts = achievement.target > 1
        self.init(
            title: achievement.title, detail: achievement.detail(guides: guides),
            progress: WebSnapshot.Month.rounded(state.progress),
            done: counts ? min(state.value, achievement.target) : nil,
            target: counts ? achievement.target : nil, xp: achievement.xp > 0 ? achievement.xp : nil
        )
    }
}

extension WebSnapshot.RecentAchievement {
    init(_ achievement: Achievement, unlockedOn date: Date?) {
        self.init(
            title: achievement.title, tier: WebSnapshot.Tier(achievement.tier),
            unlockedOn: date.map(WebDay.string), xp: achievement.xp > 0 ? achievement.xp : nil)
    }
}

extension WebSnapshot.Tier {
    init(_ tier: Achievement.Tier) {
        switch tier {
        case .bronze: self = .bronze
        case .silver: self = .silver
        case .gold: self = .gold
        }
    }
}
