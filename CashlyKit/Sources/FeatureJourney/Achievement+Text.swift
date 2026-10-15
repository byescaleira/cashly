import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import FeatureCore
import SwiftUI

extension Achievement {
    var title: String {
        switch group {
        case .firstSteps: firstStepTitle
        case .consistency: consistencyTitle
        case .inTheBlue: blueTitle
        case .volume: volumeTitle
        case .secret: secretTitle
        case .pro: proTitle
        case .organization, .together, .challenges, .levels: milestoneTitle
        }
    }

    var detail: String {
        switch group {
        case .firstSteps: firstStepDetail
        case .consistency:
            String(
                appLocalized:
                    "Keep a streak of \(target) days: every day, record something or mark a no-spend day."
            )
        case .inTheBlue: blueDetail
        case .volume:
            String(appLocalized: "Record \(target) transactions in total, expenses and income.")
        case .secret: secretDetail
        case .pro: proDetail
        case .organization, .together, .challenges, .levels: milestoneDetail
        }
    }

    var symbol: String {
        switch group {
        case .firstSteps: firstStepSymbol
        case .consistency: "flame.fill"
        case .inTheBlue: self == .perfectMonth ? "star.fill" : "checkmark.seal.fill"
        case .volume: "list.bullet"
        case .organization: organizationSymbol
        case .together: "person.2.fill"
        case .challenges: "flag.checkered"
        case .levels: "arrow.up.circle.fill"
        case .pro: "crown.fill"
        case .secret: "sparkles"
        }
    }

    private var firstStepTitle: String {
        switch self {
        case .firstCategory: String(appLocalized: "A Place for Everything")
        case .firstBudget: String(appLocalized: "The Plan")
        case .firstTag: String(appLocalized: "Tag, You're It")
        case .firstSplit: String(appLocalized: "Fair Share")
        case .firstBackup: String(appLocalized: "Safety Net")
        default: String(appLocalized: "Day One")
        }
    }

    private var consistencyTitle: String {
        switch self {
        case .streak7: String(appLocalized: "One Week Strong")
        case .streak30: String(appLocalized: "Monthly Habit")
        case .streak100: String(appLocalized: "Triple Digits")
        default: String(appLocalized: "Full Orbit")
        }
    }

    private var blueTitle: String {
        switch self {
        case .blueRun3: String(appLocalized: "Blue Quarter")
        case .blueRun6: String(appLocalized: "Blue Half-Year")
        case .blueRun12: String(appLocalized: "Blue Year")
        case .perfectMonth: String(appLocalized: "Flawless")
        default: String(appLocalized: "In the Blue")
        }
    }

    private var volumeTitle: String {
        switch self {
        case .transactions100: String(appLocalized: "Hundred Club")
        case .transactions500: String(appLocalized: "Five Hundred Club")
        case .transactions1000: String(appLocalized: "Thousand Club")
        default: String(appLocalized: "Archivist")
        }
    }

    private var milestoneTitle: String {
        switch self {
        case .tagsInUse5: String(appLocalized: "Well Tagged")
        case .fullyBudgeted: String(appLocalized: "Nothing Left to Chance")
        case .allGuides: String(appLocalized: "Read the Manual")
        case .splits10: String(appLocalized: "Better Together")
        case .splits50: String(appLocalized: "Group Treasurer")
        case .challenges1: String(appLocalized: "Challenge Accepted")
        case .challenges5: String(appLocalized: "Determined")
        case .challenges12: String(appLocalized: "Unstoppable")
        case .level10: String(appLocalized: "Double Digits")
        default: String(appLocalized: "Quarter Century")
        }
    }

    private var proTitle: String {
        switch self {
        case .proMonth1: String(appLocalized: "Supporter")
        case .proMonth6: String(appLocalized: "Patron")
        case .proYear1: String(appLocalized: "Gold Member")
        default: String(appLocalized: "Hall of Fame")
        }
    }

    private var proDetail: String {
        switch self {
        case .proMonth1: String(appLocalized: "Have Cashly Pro for a month in total.")
        case .proMonth6: String(appLocalized: "Have Cashly Pro for six months in total.")
        case .proYear1: String(appLocalized: "Have Cashly Pro for a year in total.")
        default: String(appLocalized: "Have Cashly Pro for two years in total.")
        }
    }

    private var secretTitle: String {
        switch self {
        case .theAnswer: String(appLocalized: "The Answer")
        case .sequence: String(appLocalized: "One, Two, Three")
        case .halloween: String(appLocalized: "Trick or Treat")
        case .newYear: String(appLocalized: "Fresh Start")
        default: String(appLocalized: "Early Bird")
        }
    }

    private var firstStepDetail: String {
        switch self {
        case .firstCategory: String(appLocalized: "Create your first category.")
        case .firstBudget: String(appLocalized: "Plan a budget for any category, in any month.")
        case .firstTag: String(appLocalized: "Create your first tag.")
        case .firstSplit:
            String(appLocalized: "Record an expense split with at least one other person.")
        case .firstBackup: String(appLocalized: "Export a backup of your data.")
        default: String(appLocalized: "Record your first transaction, an expense or an income.")
        }
    }

    private var blueDetail: String {
        switch self {
        case .blueMonth:
            String(appLocalized: "Close a month with a health score of 895 or more.")
        case .perfectMonth:
            String(appLocalized: "Close a month with the top health score, 1,000.")
        default:
            String(
                appLocalized: "Close \(target) months in a row with a health score of 895 or more.")
        }
    }

    private var milestoneDetail: String {
        switch self {
        case .tagsInUse5:
            String(appLocalized: "Use \(target) different tags on your transactions.")
        case .fullyBudgeted:
            String(appLocalized: "Give every category a budget in the current month.")
        case .allGuides: String(appLocalized: "Finish all \(Guide.free.count) guides.")
        case .splits10, .splits50:
            String(appLocalized: "Record \(target) expenses split with other people.")
        case .challenges1: String(appLocalized: "Complete a challenge before it ends.")
        case .challenges5, .challenges12: String(appLocalized: "Complete \(target) challenges.")
        default:
            String(
                appLocalized:
                    "Reach level \(target), at \(GameLevel.threshold(target).formatted(.number.locale(.app))) XP in total."
            )
        }
    }

    private var secretDetail: String {
        switch self {
        case .theAnswer, .sequence:
            String(appLocalized: "Record a transaction of exactly \(secretAmount).")
        case .halloween: String(appLocalized: "Record a transaction dated October 31.")
        case .newYear: String(appLocalized: "Record a transaction dated January 1.")
        default: String(appLocalized: "Record a transaction at 4:44 in the morning.")
        }
    }

    private var secretAmount: String {
        Money(minorUnits: self == .theAnswer ? 4_200 : 123_456).doubleValue.formatted(.appCurrency)
    }

    private var firstStepSymbol: String {
        switch self {
        case .firstCategory: "square.grid.2x2.fill"
        case .firstBudget: "chart.pie.fill"
        case .firstTag: "tag.fill"
        case .firstSplit: "person.2.fill"
        case .firstBackup: "externaldrive.fill"
        default: "plus.circle.fill"
        }
    }

    private var organizationSymbol: String {
        switch self {
        case .tagsInUse5: "tag.fill"
        case .fullyBudgeted: "checklist"
        default: "book.fill"
        }
    }
}

extension Achievement.Tier {
    var title: String {
        switch self {
        case .bronze: String(appLocalized: "Bronze")
        case .silver: String(appLocalized: "Silver")
        case .gold: String(appLocalized: "Gold")
        }
    }

    var color: Color {
        switch self {
        case .bronze: .retroBrown
        case .silver: .retroDenim
        case .gold: .retroMustard
        }
    }
}

extension AchievementState {
    var isHidden: Bool { achievement.isSecret && !isUnlocked }
    var title: String { isHidden ? String(appLocalized: "Secret") : achievement.title }
    var detail: String {
        isHidden
            ? String(appLocalized: "Secret achievements show what they ask once you find them.")
            : achievement.detail
    }
    var symbol: String { isHidden ? "questionmark" : achievement.symbol }
}
