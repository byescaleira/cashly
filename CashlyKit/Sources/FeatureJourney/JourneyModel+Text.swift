import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

extension JourneyModel {
    var levelCaption: String {
        guard let level = progress?.level else { return "" }
        guard level.xpForNextLevel > 0 else { return String(appLocalized: "Highest level reached") }
        let missing = level.xpForNextLevel - level.xpIntoLevel
        return String(appLocalized: "\(missing) XP to level \(level.number + 1)")
    }

    var totalXP: String {
        String(appLocalized: "\(progress?.xp ?? 0) XP in total")
    }

    var streakTitle: String {
        String(appLocalized: "\(progress?.streak.current ?? 0) days")
    }

    var achievementsCaption: String {
        let total = progress?.achievements.count ?? 0
        return String(appLocalized: "\(unlockedCount) of \(total) unlocked")
    }

    var missionsFooter: String {
        String(appLocalized: "New missions in \(daysUntilNewMissions) days.")
    }

    var restoreTitle: String {
        String(appLocalized: "Restore the \(progress?.streak.restorable ?? 0)-day streak")
    }
}

extension JourneyModel {
    var levelHeadline: String {
        String(appLocalized: "Level \(progress?.level.number ?? 1)")
    }

    var xpCaption: String {
        guard let level = progress?.level else { return "" }
        guard level.xpForNextLevel > 0 else { return String(appLocalized: "Highest level reached") }
        return String(appLocalized: "\(level.xpIntoLevel) of \(level.xpForNextLevel) XP")
    }

    var nextTitleCaption: String {
        guard let next = progress?.level.nextRankLevel else {
            return String(appLocalized: "Highest title reached")
        }
        return String(appLocalized: "Next title: \(GameLevel.title(for: next)) at level \(next)")
    }

    var nextRankDetail: String {
        guard let levels = levelsToNextRank else { return "" }
        return String(appLocalized: "\(levels) levels to go")
    }

    var streakStatus: String {
        guard let streak = progress?.streak else { return "" }
        if streak.isTodayTracked { return String(appLocalized: "Today is done") }
        return streak.current > 0
            ? String(appLocalized: "Record something today to keep it going")
            : String(appLocalized: "Record something or mark a no-spend day to start")
    }

    var bestStreak: String {
        String(appLocalized: "\(progress?.streak.best ?? 0) days")
    }

    var freezesCaption: String {
        "\(progress?.streak.freezes ?? 0)"
    }

    var milestoneTitle: String {
        guard let milestone = streakMilestone else {
            return String(appLocalized: "Every streak mark reached")
        }
        return String(appLocalized: "Next mark: \(milestone.target) days")
    }

    var milestoneDetail: String {
        guard let milestone = streakMilestone else { return "" }
        return String(appLocalized: "\(milestone.remaining) days to go")
    }

    func valueCaption(of mission: Mission) -> String {
        "\(min(mission.value, mission.kind.target))/\(mission.kind.target)"
    }

    func valueCaption(of state: AchievementState) -> String {
        String(
            appLocalized:
                "\(min(state.value, state.achievement.target)) of \(state.achievement.target)")
    }
}
