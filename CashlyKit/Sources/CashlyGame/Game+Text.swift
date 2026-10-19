import CashlyDomain

extension GameLevel {
    public var title: String {
        switch rank {
        case 0: String(appLocalized: "Beginner")
        case 1: String(appLocalized: "Tracker")
        case 2: String(appLocalized: "Organizer")
        case 3: String(appLocalized: "Planner")
        case 4: String(appLocalized: "Saver")
        case 5: String(appLocalized: "Strategist")
        case 6: String(appLocalized: "Investor")
        case 7: String(appLocalized: "Expert")
        case 8: String(appLocalized: "Master")
        default: String(appLocalized: "Legend")
        }
    }

    public static func title(for number: Int) -> String {
        GameLevel(xp: threshold(number)).title
    }
}

extension Challenge.Kind {
    public var title: String {
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
}
