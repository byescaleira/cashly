import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import SwiftUI

extension Achievement {
    var title: String {
        switch self {
        case .firstTransaction: String(appLocalized: "First Record")
        case .firstCategory: String(appLocalized: "First Category")
        case .firstBudget: String(appLocalized: "First Budget")
        case .firstTag: String(appLocalized: "First Tag")
        case .firstSplit: String(appLocalized: "First Split")
        case .firstImport: String(appLocalized: "First Import")
        case .firstBackup: String(appLocalized: "First Backup")
        case .streak7, .streak30, .streak100, .streak365:
            String(appLocalized: "\(target)-Day Streak")
        case .blueMonth: String(appLocalized: "In the Blue")
        case .blueRun3, .blueRun6, .blueRun12: String(appLocalized: "\(target) Months in the Blue")
        case .perfectMonth: String(appLocalized: "Perfect Month")
        case .transactions100, .transactions500, .transactions1000, .transactions5000:
            String(appLocalized: "\(target) Records")
        case .tagsInUse5: String(appLocalized: "Well Tagged")
        case .fullyBudgeted: String(appLocalized: "Everything Planned")
        case .allGuides: String(appLocalized: "Studious")
        case .splits10: String(appLocalized: "Better Together")
        case .splits50: String(appLocalized: "Group Treasurer")
        case .challenges1: String(appLocalized: "Challenger")
        case .challenges5: String(appLocalized: "Determined")
        case .challenges12: String(appLocalized: "Unstoppable")
        case .level10, .level25: String(appLocalized: "Level \(target)")
        case .theAnswer: String(appLocalized: "The Answer")
        case .sequence: String(appLocalized: "In Sequence")
        case .halloween: String(appLocalized: "Spooky")
        case .newYear: String(appLocalized: "Fresh Start")
        case .earlyBird: String(appLocalized: "Early Bird")
        }
    }

    var detail: String {
        switch self {
        case .firstTransaction: String(appLocalized: "Record your first transaction.")
        case .firstCategory: String(appLocalized: "Create a category.")
        case .firstBudget: String(appLocalized: "Plan a budget.")
        case .firstTag: String(appLocalized: "Create a tag.")
        case .firstSplit: String(appLocalized: "Split an expense with someone.")
        case .firstImport: String(appLocalized: "Import a spreadsheet.")
        case .firstBackup: String(appLocalized: "Make a backup.")
        case .streak7, .streak30, .streak100, .streak365:
            String(appLocalized: "Follow your money \(target) days in a row.")
        case .blueMonth: String(appLocalized: "Close a month within budget.")
        case .blueRun3, .blueRun6, .blueRun12:
            String(appLocalized: "Close \(target) months in a row within budget.")
        case .perfectMonth: String(appLocalized: "Close a month with a score of 1,000.")
        case .transactions100, .transactions500, .transactions1000, .transactions5000:
            String(appLocalized: "Record \(target) transactions.")
        case .tagsInUse5: String(appLocalized: "Use 5 different tags.")
        case .fullyBudgeted: String(appLocalized: "Give every category a budget this month.")
        case .allGuides: String(appLocalized: "Finish every guide.")
        case .splits10, .splits50: String(appLocalized: "Split \(target) expenses.")
        case .challenges1: String(appLocalized: "Complete your first challenge.")
        case .challenges5, .challenges12: String(appLocalized: "Complete \(target) challenges.")
        case .level10, .level25: String(appLocalized: "Reach level \(target).")
        case .theAnswer: String(appLocalized: "Record an amount of exactly 42.")
        case .sequence: String(appLocalized: "Record an amount of exactly 1,234.56.")
        case .halloween: String(appLocalized: "Record something on October 31.")
        case .newYear: String(appLocalized: "Record something on January 1.")
        case .earlyBird: String(appLocalized: "Record something at 4:44 in the morning.")
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
        case .secret: "sparkles"
        }
    }

    private var firstStepSymbol: String {
        switch self {
        case .firstCategory: "square.grid.2x2.fill"
        case .firstBudget: "chart.pie.fill"
        case .firstTag: "tag.fill"
        case .firstSplit: "person.2.fill"
        case .firstImport: "tablecells.fill"
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
        isHidden ? String(appLocalized: "Keep using Cashly to find out.") : achievement.detail
    }
    var symbol: String { isHidden ? "questionmark" : achievement.symbol }
}
