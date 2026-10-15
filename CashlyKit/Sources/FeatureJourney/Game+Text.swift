import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import SwiftUI

extension GameLevel {
    var title: String {
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
}

extension Mission.Kind {
    var title: String {
        switch self {
        case .recordFive, .recordTen: String(appLocalized: "Record \(target) transactions")
        case .trackFourDays, .trackSixDays:
            String(appLocalized: "Follow your money on \(target) days")
        case .noSpendDay: String(appLocalized: "Mark a no-spend day")
        case .useTags: String(appLocalized: "Tag \(target) new transactions")
        case .splitExpense: String(appLocalized: "Split an expense")
        case .backup: String(appLocalized: "Make a backup")
        }
    }

    var symbol: String {
        switch self {
        case .recordFive, .recordTen: "plus.circle.fill"
        case .trackFourDays, .trackSixDays: "calendar"
        case .noSpendDay: "hand.raised.fill"
        case .useTags: "tag.fill"
        case .splitExpense: "person.2.fill"
        case .backup: "externaldrive.fill"
        }
    }
}

extension Celebration {
    var title: String {
        switch self {
        case .level(let number): String(appLocalized: "Level \(number)")
        case .achievement(let achievement): achievement.title
        }
    }

    var detail: String {
        switch self {
        case .level(let number): GameLevel.title(for: number)
        case .achievement(let achievement): achievement.detail
        }
    }

    var symbol: String {
        switch self {
        case .level: "arrow.up.circle.fill"
        case .achievement(let achievement): achievement.symbol
        }
    }

    var color: Color {
        switch self {
        case .level: .retroTeal
        case .achievement(let achievement): achievement.tier.color
        }
    }
}

extension GameLevel {
    static func title(for number: Int) -> String {
        GameLevel(xp: threshold(number)).title
    }
}

extension Achievement.Group {
    var title: String {
        switch self {
        case .firstSteps: String(appLocalized: "First Steps")
        case .consistency: String(appLocalized: "Consistency")
        case .inTheBlue: String(appLocalized: "In the Blue")
        case .volume: String(appLocalized: "Volume")
        case .organization: String(appLocalized: "Organization")
        case .together: String(appLocalized: "Together")
        case .challenges: String(appLocalized: "Challenges")
        case .levels: String(appLocalized: "Levels")
        case .pro: String(appLocalized: "Cashly Pro")
        case .secret: String(appLocalized: "Secrets")
        }
    }
}

extension Streak.Day.State {
    var title: String {
        switch self {
        case .tracked: String(appLocalized: "Followed")
        case .covered: String(appLocalized: "Covered by a freeze")
        case .missed: String(appLocalized: "Missed")
        }
    }
}
