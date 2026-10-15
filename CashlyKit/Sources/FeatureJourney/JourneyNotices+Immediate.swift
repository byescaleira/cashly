import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

extension JourneyNotices {
    public var baseline: JourneyBaseline {
        JourneyBaseline(level: progress.level.number, achievements: Set(unlocked))
    }

    public func immediate(since baseline: JourneyBaseline?) -> [Reminder] {
        [levelUp(since: baseline), milestone(since: baseline)].compactMap { $0 }
            + achievements(since: baseline) + challengeResults + [pace].compactMap { $0 }
    }

    private var unlocked: [Achievement] {
        progress.achievements.filter(\.isUnlocked).map(\.achievement)
    }

    private func levelUp(since baseline: JourneyBaseline?) -> Reminder? {
        let level = progress.level
        guard let baseline, level.number > baseline.level else { return nil }
        let previous = GameLevel(xp: GameLevel.threshold(max(baseline.level, 1)))
        let body =
            level.rank > previous.rank
            ? String(appLocalized: "New title: \(level.title). Keep going for the next one.")
            : level.xpForNextLevel > 0
                ? String(
                    appLocalized:
                        "\(level.xpForNextLevel - level.xpIntoLevel) XP to level \(level.number + 1)"
                )
                : String(appLocalized: "Highest level reached")
        return instant(
            "level.\(level.number)", title: String(appLocalized: "Level \(level.number) reached"),
            body: body)
    }

    private func milestone(since baseline: JourneyBaseline?) -> Reminder? {
        let streak = progress.streak
        guard streak.isTodayTracked,
            let achievement = Achievement.allCases.first(where: {
                $0.group == .consistency && $0.target == streak.current
            })
        else { return nil }
        let isNew = baseline.map { !$0.achievements.contains(achievement) } ?? false
        let body =
            isNew
            ? unlockedTitle(achievement) + " " + String(appLocalized: "+\(achievement.xp) XP")
            : String(appLocalized: "Come back tomorrow to keep it going.")
        let date = calendar.dateComponents([.year, .month, .day], from: today)
        return instant(
            "milestone.\(streak.current).\(date.year ?? 0)-\(date.month ?? 0)-\(date.day ?? 0)",
            title: String(appLocalized: "\(streak.current)-day streak!"), body: body)
    }

    private func achievements(since baseline: JourneyBaseline?) -> [Reminder] {
        guard let baseline else { return [] }
        return unlocked.filter { !baseline.achievements.contains($0) && $0.group != .consistency }
            .map {
                instant(
                    "achievement.\($0.rawValue)", title: unlockedTitle($0),
                    body: $0.detail + " " + String(appLocalized: "+\($0.xp) XP"))
            }
    }

    private var challengeResults: [Reminder] {
        guard let recent = calendar.date(byAdding: .day, value: -1, to: today) else { return [] }
        return progress.recentChallenges.filter { $0.end >= recent }.map { state in
            let id = "challenge.\(Int(state.start.timeIntervalSince1970))"
            let title = state.challenge.kind.title
            guard state.status == .completed else {
                return instant(
                    id, title: String(appLocalized: "Challenge lost: \(title)"),
                    body: String(
                        appLocalized: "\(state.caption). Try another challenge in the Journey."))
            }
            return instant(
                id, title: String(appLocalized: "Challenge complete: \(title)"),
                body: String(
                    appLocalized: "+\(state.xp) XP. Pick your next challenge in the Journey."))
        }
    }

    private var pace: Reminder? {
        guard let state = progress.challenge,
            let outlook = ChallengeOutlook(state, today: now, calendar: calendar),
            let pace = outlook.pace, pace != .steady
        else { return nil }
        let isOver = pace == .over
        let days = String(appLocalized: "\(outlook.daysLeft) days left")
        return instant(
            "pace.\(Int(state.start.timeIntervalSince1970)).\(isOver ? "over" : "fast")",
            title: isOver
                ? String(appLocalized: "You've hit your challenge limit")
                : String(appLocalized: "Slow down to keep your challenge"),
            body: "\(state.challenge.kind.title) · \(state.caption) · \(days)")
    }

    private func unlockedTitle(_ achievement: Achievement) -> String {
        String(appLocalized: "Achievement unlocked: \(achievement.title)")
    }

    private func instant(_ id: String, title: String, body: String) -> Reminder {
        Reminder(
            id: "journey.alert.\(userID).\(id)", title: title, body: body,
            components: DateComponents(),
            category: NotificationCategory.journey,
            userInfo: [NotificationCategory.linkKey: JourneyNotices.journeyLink])
    }
}
