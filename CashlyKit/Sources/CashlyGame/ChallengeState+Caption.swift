import CashlyDomain
import Foundation

extension ChallengeState {
    public var caption: String {
        let shown = min(measure.value, measure.target)
        switch challenge.kind {
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

    private func money(_ minorUnits: Int64) -> String {
        GameMoney.text(minorUnits)
    }
}
