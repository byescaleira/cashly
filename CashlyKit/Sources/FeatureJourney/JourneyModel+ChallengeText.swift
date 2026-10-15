import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

extension JourneyModel {
    func detail(of state: ChallengeState) -> String {
        let challenge = state.challenge
        let category = categories.first { $0.id == challenge.categoryID }?.name ?? ""
        let target = money(state.measure.target)
        switch challenge.kind {
        case .noSpendWeek:
            return String(appLocalized: "Seven days without spending on \(category).")
        case .cap:
            return String(appLocalized: "Up to \(target) on \(category) this month.")
        case .lessThanLastMonth:
            return String(appLocalized: "Spend less on \(category) than last month.")
        case .cutBiggest:
            return String(appLocalized: "Up to \(target) on \(category) this month.")
        case .belowAverage, .weeklyBudget:
            return String(appLocalized: "Up to \(target) until \(day(state.end)).")
        default:
            return challenge.kind.detail
        }
    }

    func progressCaption(of state: ChallengeState) -> String {
        let measure = state.measure
        let shown = min(measure.value, measure.target)
        switch state.challenge.kind {
        case .lessThanLastMonth:
            let ratio = measure.target > 0 ? Double(measure.value) / Double(measure.target) : 0
            let percent = ratio.formatted(.percent.precision(.fractionLength(0)).locale(.app))
            return String(appLocalized: "\(percent) of last month")
        case .cap, .cutBiggest, .belowAverage, .weeklyBudget:
            return String(appLocalized: "\(money(measure.value)) of \(money(measure.target))")
        case .weekendLighter:
            return String(
                appLocalized:
                    "Weekends \(money(measure.value)) a day, weekdays \(money(measure.target))")
        case .noSpendWeekend, .noSpendWeek:
            return String(appLocalized: "Clean days: \(measure.value)/\(measure.target)")
        case .quietDays:
            return String(appLocalized: "Quiet days: \(shown)/\(measure.target)")
        case .trackWeek, .sameDay, .everyDay:
            return String(appLocalized: "Days followed: \(measure.value)/\(measure.target)")
        case .tagWeek:
            return String(appLocalized: "Tagged expenses: \(shown)/\(measure.target)")
        case .planEveryCategory:
            return String(
                appLocalized: "Categories with a budget: \(measure.value)/\(measure.target)")
        case .allBudgetsBlue:
            return String(appLocalized: "Budgets in the blue: \(measure.value)/\(measure.target)")
        case .blueMonth:
            return String(appLocalized: "Score \(measure.value), needs \(measure.target)")
        }
    }

    func daysLeftCaption(_ outlook: ChallengeOutlook) -> String {
        String(appLocalized: "\(outlook.daysLeft) days left")
    }

    func paceTitle(_ pace: ChallengeOutlook.Pace, of state: ChallengeState) -> String {
        let isMonth = state.challenge.kind.length == .month
        switch pace {
        case .steady:
            return isMonth
                ? String(appLocalized: "On pace with the month")
                : String(appLocalized: "On pace with the week")
        case .fast:
            return isMonth
                ? String(appLocalized: "Faster than the month")
                : String(appLocalized: "Faster than the week")
        case .over: return String(appLocalized: "Over the target")
        }
    }

    func ending(of state: ChallengeState) -> String {
        String(appLocalized: "Ends on \(day(state.end))")
    }

    var challengeFooter: String {
        guard let progress else { return "" }
        let done = String(appLocalized: "Completed challenges: \(progress.completedChallenges).")
        return String(appLocalized: "One challenge at a time.") + " " + costCaption + " " + done
    }

    var costCaption: String {
        switch challengeCost {
        case .free: String(appLocalized: "The first challenge of the month is free.")
        case .reroll, .locked:
            String(appLocalized: "Rerolls left this month: \(progress?.rerolls ?? 0).")
        }
    }

    var catalogCaption: String {
        String(appLocalized: "\(Challenge.Kind.allCases.count) challenges")
    }

    func day(_ end: Date) -> String {
        end.addingTimeInterval(-1).formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: .app))
    }

    func money(_ minorUnits: Int64) -> String {
        Money(minorUnits: minorUnits).doubleValue.formatted(.appCurrency)
    }
}
