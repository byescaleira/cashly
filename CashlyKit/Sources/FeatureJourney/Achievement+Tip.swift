import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

public enum AchievementAction: Equatable {
    case open(Route)
    case guide(Guide)
    case challenge

    var requiresPro: Bool { self == .guide(.importSpreadsheet) }
}

extension Achievement {
    var tip: String {
        switch group {
        case .firstSteps: firstStepTip
        case .consistency:
            String(
                appLocalized:
                    "Record something today, or tap I Didn't Spend Today in Journey. A freeze covers a missed day."
            )
        case .inTheBlue: blueTip
        case .volume:
            String(
                appLocalized:
                    "Record as you go, small things included. Up to \(GameEngine.dailyTransactionLimit) a day also earn XP."
            )
        case .organization: organizationTip
        case .together:
            String(
                appLocalized:
                    "When you share an expense, add the people in the editor. Each split expense counts once."
            )
        case .challenges:
            String(appLocalized: "Pick a challenge in Journey. The first one each month is free.")
        case .levels:
            String(appLocalized: "Recording, streaks, missions and challenges all earn XP.")
        case .secret: clue
        }
    }

    var clue: String {
        switch self {
        case .theAnswer:
            String(appLocalized: "Think of the answer to life, the universe and everything.")
        case .sequence: String(appLocalized: "Some amounts just count up.")
        case .halloween: String(appLocalized: "Something spooky happens one night in October.")
        case .newYear: String(appLocalized: "The calendar has a fresh first page.")
        default: String(appLocalized: "Some people record before sunrise. Way before.")
        }
    }

    var action: AchievementAction? {
        switch self {
        case .firstCategory: .open(.addCategory(id: nil))
        case .firstBudget: .open(.addBudget(id: nil, categoryID: nil, date: nil))
        case .firstTag: .open(.addTag(id: nil))
        case .firstImport: .guide(.importSpreadsheet)
        case .firstBackup: .guide(.backups)
        case .fullyBudgeted, .blueMonth, .blueRun3, .blueRun6, .blueRun12, .perfectMonth:
            .open(.budgets)
        case .challenges1, .challenges5, .challenges12: .challenge
        case .allGuides, .level10, .level25: nil
        default: isSecret ? nil : .open(.addTransaction(id: nil))
        }
    }

    private var firstStepTip: String {
        switch self {
        case .firstCategory:
            String(appLocalized: "Name it the way you think about money: Groceries, Rent, Fun.")
        case .firstBudget:
            String(
                appLocalized:
                    "Pick a category you spend on every month and set a limit you can keep.")
        case .firstTag:
            String(
                appLocalized:
                    "Tags cut across categories, like Trip or Work. Create one, then add it when you record."
            )
        case .firstSplit:
            String(
                appLocalized: "In the transaction editor, add participants and choose the split.")
        case .firstImport:
            String(
                appLocalized:
                    "The import guide shows the columns Cashly reads and checks the file before saving."
            )
        case .firstBackup:
            String(appLocalized: "Settings › Data › Export Backup saves a file with every profile.")
        default: String(appLocalized: "Any amount counts, even a coffee. It takes a few seconds.")
        }
    }

    private var blueTip: String {
        switch self {
        case .blueMonth:
            String(
                appLocalized:
                    "Keep the month's spending within the total of your budgets. A month counts once it closes."
            )
        case .perfectMonth:
            String(
                appLocalized:
                    "Spend at most \(BudgetHealth.fullScoreUsage.formatted(.percent.locale(.app))) of the month's budget total."
            )
        default:
            String(
                appLocalized:
                    "A month below 895 restarts the run, so check your budgets before each month ends."
            )
        }
    }

    private var organizationTip: String {
        switch self {
        case .tagsInUse5:
            String(
                appLocalized:
                    "Add a tag when you record: Trip, Work, Gift. Each different tag counts once.")
        case .fullyBudgeted:
            String(
                appLocalized:
                    "Open Budgets and add a limit to each category that still has none this month.")
        default:
            String(
                appLocalized:
                    "Guides are in Settings. Each one you finish also earns \(GameEngine.guideXP) XP."
            )
        }
    }
}
