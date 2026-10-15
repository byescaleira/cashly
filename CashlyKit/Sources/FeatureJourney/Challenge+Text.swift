import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import SwiftUI

extension Challenge.Kind {
    var title: String {
        switch self {
        case .noSpendWeekend: String(appLocalized: "No-Spend Weekend")
        case .quietDays: String(appLocalized: "Three Quiet Days")
        case .noSpendWeek: String(appLocalized: "No-Spend Week")
        case .weekendLighter: String(appLocalized: "Lighter Weekend")
        case .belowAverage: String(appLocalized: "Below Your Average")
        case .cap: String(appLocalized: "Spending Cap")
        case .lessThanLastMonth: String(appLocalized: "Less Than Last Month")
        case .cutBiggest: String(appLocalized: "Cut the Biggest")
        case .trackWeek: String(appLocalized: "Seven-Day Check-In")
        case .tagWeek: String(appLocalized: "Tagged Week")
        case .sameDay: String(appLocalized: "Same-Day Records")
        case .everyDay: String(appLocalized: "Every Day")
        case .planEveryCategory: String(appLocalized: "Plan Every Category")
        case .weeklyBudget: String(appLocalized: "Week on Budget")
        case .blueMonth: String(appLocalized: "Month in the Blue")
        case .allBudgetsBlue: String(appLocalized: "Every Budget in the Blue")
        }
    }

    var detail: String {
        switch self {
        case .noSpendWeekend: String(appLocalized: "Spend nothing at all on Saturday and Sunday.")
        case .quietDays:
            String(appLocalized: "Three days this week with nothing spent, recorded or marked.")
        case .noSpendWeek: String(appLocalized: "Seven days without spending in one category.")
        case .weekendLighter:
            String(appLocalized: "Spend less a day on the weekend than on weekdays this week.")
        case .belowAverage:
            String(appLocalized: "Keep this week under your average week of the last month.")
        case .cap: String(appLocalized: "Keep one category under an amount this month.")
        case .lessThanLastMonth:
            String(appLocalized: "Spend less in one category than last month.")
        case .cutBiggest:
            String(
                appLocalized: "Spend \(Challenge.cutShare) less on last month's biggest category.")
        case .trackWeek: String(appLocalized: "Follow your money every day for seven days.")
        case .tagWeek: String(appLocalized: "Tag every expense this week, at least three of them.")
        case .sameDay:
            String(appLocalized: "Record each expense on the day it happens, every day this week.")
        case .everyDay: String(appLocalized: "Follow your money every day until the month ends.")
        case .planEveryCategory:
            String(appLocalized: "Give a budget to every category you spend on this month.")
        case .weeklyBudget:
            String(appLocalized: "Spend no more than a week's share of this month's budgets.")
        case .blueMonth: String(appLocalized: "End the month within budget.")
        case .allBudgetsBlue:
            String(appLocalized: "Keep every budget of the month within its amount.")
        }
    }

    var symbol: String {
        switch self {
        case .noSpendWeekend: "sun.max.fill"
        case .quietDays: "moon.zzz.fill"
        case .noSpendWeek: "nosign"
        case .weekendLighter: "scalemass.fill"
        case .belowAverage: "chart.line.downtrend.xyaxis"
        case .cap: "gauge.with.dots.needle.33percent"
        case .lessThanLastMonth: "arrow.down.right.circle.fill"
        case .cutBiggest: "scissors"
        case .trackWeek: "checkmark.circle.fill"
        case .tagWeek: "tag.fill"
        case .sameDay: "clock.fill"
        case .everyDay: "calendar"
        case .planEveryCategory: "list.bullet.clipboard.fill"
        case .weeklyBudget: "calendar.badge.clock"
        case .blueMonth: "checkmark.seal.fill"
        case .allBudgetsBlue: "square.grid.2x2.fill"
        }
    }

    var color: Color { theme.color }
}

extension Challenge {
    static var cutShare: String {
        (Double(cutPercent) / 100).formatted(.percent.precision(.fractionLength(0)).locale(.app))
    }
}

extension Challenge.Theme {
    var title: String {
        switch self {
        case .spendLess: String(appLocalized: "Spend Less")
        case .limits: String(appLocalized: "Limits")
        case .habits: String(appLocalized: "Habits")
        case .budgets: String(appLocalized: "Budgets")
        }
    }

    var detail: String {
        switch self {
        case .spendLess: String(appLocalized: "Days and weekends with nothing, or less, going out.")
        case .limits: String(appLocalized: "Amounts to stay under, measured by your own history.")
        case .habits: String(appLocalized: "Small routines that keep your records complete.")
        case .budgets: String(appLocalized: "Challenges built on this month's budgets.")
        }
    }

    var symbol: String {
        switch self {
        case .spendLess: "leaf"
        case .limits: "gauge.with.needle"
        case .habits: "repeat"
        case .budgets: "chart.bar"
        }
    }

    var color: Color {
        switch self {
        case .spendLess: .retroOlive
        case .limits: .retroOrange
        case .habits: .retroTeal
        case .budgets: .retroDenim
        }
    }
}

extension Challenge.Length {
    var title: String {
        switch self {
        case .weekend: String(appLocalized: "Weekend")
        case .week: String(appLocalized: "\(Challenge.weekDays) days")
        case .month: String(appLocalized: "Month")
        }
    }

    var symbol: String {
        switch self {
        case .weekend: "sun.max"
        case .week: "calendar"
        case .month: "calendar.circle"
        }
    }
}

extension Challenge.Difficulty {
    var title: String {
        switch self {
        case .easy: String(appLocalized: "Easy")
        case .medium: String(appLocalized: "Medium")
        case .hard: String(appLocalized: "Hard")
        }
    }

    var color: Color {
        switch self {
        case .easy: .positive
        case .medium: .warning
        case .hard: .negative
        }
    }
}

extension ChallengeHints.Blocker {
    var title: String {
        switch self {
        case .needsCategories: String(appLocalized: "Create a category first.")
        case .needsHistory: String(appLocalized: "Needs a few weeks of expenses.")
        case .needsLastMonth: String(appLocalized: "Needs expenses from last month.")
        case .needsBudget: String(appLocalized: "Needs a budget this month.")
        case .needsTags: String(appLocalized: "Create a tag first.")
        case .alreadyPlanned: String(appLocalized: "Every category already has a budget.")
        }
    }
}
