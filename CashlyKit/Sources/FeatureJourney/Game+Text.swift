import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import SwiftUI

extension Mission.Kind {
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

    var levelText: String? {
        guard case .level(let number) = self else { return nil }
        return number.formatted(.number.locale(.app))
    }

    var color: Color {
        switch self {
        case .level: .retroTeal
        case .achievement(let achievement): achievement.tier.color
        }
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
