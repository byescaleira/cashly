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

    var streakCaption: String {
        guard let streak = progress?.streak else { return "" }
        let best = String(appLocalized: "Best: \(streak.best) days")
        let freezes = String(appLocalized: "\(streak.freezes) freezes")
        return best + " · " + freezes
    }

    var achievementsCaption: String {
        let states = progress?.achievements ?? []
        let unlocked = states.filter(\.isUnlocked).count
        return String(appLocalized: "\(unlocked) of \(states.count) unlocked")
    }

    var missionsFooter: String {
        String(appLocalized: "New missions every Monday. Each one is worth \(Mission.xp) XP.")
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
}
