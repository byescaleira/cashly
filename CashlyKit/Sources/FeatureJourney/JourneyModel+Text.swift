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

    func detail(of challenge: Challenge) -> String {
        let category = categories.first { $0.id == challenge.categoryID }?.name ?? ""
        switch challenge.kind {
        case .noSpendWeek:
            return String(appLocalized: "Seven days without spending on \(category).")
        case .cap:
            let limit = Money(minorUnits: challenge.limit ?? 0).doubleValue
            return String(
                appLocalized: "Up to \(limit.formatted(.appCurrency)) on \(category) this month.")
        case .lessThanLastMonth:
            return String(appLocalized: "Spend less on \(category) than last month.")
        case .blueMonth, .everyDay: return challenge.kind.detail
        }
    }

    func ending(of state: ChallengeState) -> String {
        let date = state.end.addingTimeInterval(-1).formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: .app))
        return String(appLocalized: "Ends on \(date)")
    }

    var challengeFooter: String {
        guard let progress else { return "" }
        let done = String(appLocalized: "Completed challenges: \(progress.completedChallenges).")
        let rule =
            progress.challengeStartsThisMonth == 0
            ? String(appLocalized: "The first challenge of the month is free.")
            : String(appLocalized: "Rerolls left this month: \(progress.rerolls).")
        return String(appLocalized: "One challenge at a time.") + " " + rule + " " + done
    }

    var restoreTitle: String {
        String(appLocalized: "Restore the \(progress?.streak.restorable ?? 0)-day streak")
    }

    var draftFooter: String {
        let reward = String(appLocalized: "Worth \(draft.kind.xp) XP.")
        guard progress?.challenge != nil else { return draft.kind.detail + " " + reward }
        return draft.kind.detail + " " + reward + " "
            + String(appLocalized: "Starting it ends the current challenge.")
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

    func progressCaption(of state: ChallengeState, outlook: ChallengeOutlook) -> String {
        let percent = outlook.progress.formatted(
            .percent.precision(.fractionLength(0)).locale(.app))
        switch state.challenge.kind {
        case .cap:
            let limit = Money(minorUnits: state.challenge.limit ?? 0).doubleValue
            let spent = (limit * outlook.progress).formatted(.appCurrency)
            return String(appLocalized: "\(spent) of \(limit.formatted(.appCurrency))")
        case .lessThanLastMonth:
            return String(appLocalized: "\(percent) of last month")
        case .noSpendWeek, .blueMonth, .everyDay:
            return String(appLocalized: "\(percent) done")
        }
    }

    func daysLeftCaption(_ outlook: ChallengeOutlook) -> String {
        String(appLocalized: "\(outlook.daysLeft) days left")
    }

    func valueCaption(of state: AchievementState) -> String {
        String(
            appLocalized:
                "\(min(state.value, state.achievement.target)) of \(state.achievement.target)")
    }
}

extension ChallengeOutlook.Pace {
    var title: String {
        switch self {
        case .steady: String(appLocalized: "On pace with the month")
        case .fast: String(appLocalized: "Faster than the month")
        case .over: String(appLocalized: "Over the target")
        }
    }

    var symbol: String {
        switch self {
        case .steady: "checkmark.circle"
        case .fast: "hare"
        case .over: "exclamationmark.triangle"
        }
    }
}
