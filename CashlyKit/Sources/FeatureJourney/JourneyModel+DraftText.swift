import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

extension JourneyModel {
    var draftPeriodText: String {
        let period = draftPeriod
        let calendar = CashlyCalendar.current
        let last = weekday(period.end.addingTimeInterval(-1))
        guard period.start > calendar.startOfDay(for: now()) else {
            return String(appLocalized: "From today until \(last)")
        }
        return String(appLocalized: "From \(weekday(period.start)) until \(last)")
    }

    var draftGoal: String? {
        let hints = progress?.challengeHints
        let category = draftCategoryName
        switch draft.kind {
        case .noSpendWeek:
            return String(appLocalized: "No spending on \(category).")
        case .cap:
            let limit = draft.limit.formatted(.appCurrency)
            return String(appLocalized: "Up to \(limit) on \(category) this month.")
        case .lessThanLastMonth:
            let previous = money(hints?.lastMonth[draft.categoryID ?? ""] ?? 0)
            return String(appLocalized: "Less than \(previous) on \(category) this month.")
        case .cutBiggest:
            let target = money(hints?.cutTarget(for: draft.categoryID) ?? 0)
            return String(appLocalized: "Up to \(target) on \(category) this month.")
        case .belowAverage:
            return String(appLocalized: "Up to \(money(hints?.weeklyAverage ?? 0)) this week.")
        case .weeklyBudget:
            return String(appLocalized: "Up to \(money(hints?.weeklyBudget ?? 0)) this week.")
        default:
            return nil
        }
    }

    var lastMonthCaption: String? {
        guard draft.kind == .lessThanLastMonth || draft.kind == .cutBiggest,
            let id = draft.categoryID
        else { return nil }
        let previous = progress?.challengeHints.lastMonth[id] ?? 0
        return String(appLocalized: "Last month: \(money(previous))")
    }

    var suggestionCaption: String? {
        guard let suggestedLimit else { return nil }
        let share = (Double(JourneyModel.suggestedShare) / 100).formatted(
            .percent.precision(.fractionLength(0)).locale(.app))
        return String(
            appLocalized:
                "Use \(suggestedLimit.formatted(.appCurrency)), \(share) of your monthly average")
    }

    var draftReward: String {
        String(appLocalized: "+\(draft.kind.xp) XP")
    }

    var draftCostText: String {
        switch challengeCost {
        case .free: String(appLocalized: "Free: first challenge of the month")
        case .reroll(let left): String(appLocalized: "Uses a reroll. Rerolls left: \(left).")
        case .locked: String(appLocalized: "No rerolls left this month.")
        }
    }

    var draftWarning: String? {
        progress?.challenge == nil
            ? nil : String(appLocalized: "Starting it ends the current challenge.")
    }

    func recentPeriod(of state: ChallengeState) -> String {
        let first = max(CashlyCalendar.current.startOfDay(for: state.start), state.from)
        let last = max(state.end.addingTimeInterval(-1), first)
        let style = Date.IntervalFormatStyle(date: .abbreviated, time: .omitted, locale: .app)
        return style.format(first..<last)
    }

    func recentOutcome(of state: ChallengeState) -> String {
        state.status == .completed
            ? String(appLocalized: "+\(state.challenge.kind.xp) XP")
            : String(appLocalized: "Missed")
    }

    private func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(.app))
    }
}
