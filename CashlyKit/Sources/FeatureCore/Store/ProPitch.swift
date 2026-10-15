import SwiftUI

public enum ProPitch: CaseIterable, Sendable {
    case forecast, history, unusual, future, variance, tags, score
    case intelligence, backups, imports, claudeCode

    public var section: LocalizedStringKey {
        switch self {
        case .forecast: "Month Forecast"
        case .history: "Compared with Other Months"
        case .unusual: "Out of the Ordinary"
        case .future: "Coming Months"
        case .variance: "Planned × Spent"
        case .tags: "Tags"
        case .score: "Score"
        case .intelligence: "Intelligence"
        case .backups: "Backup"
        case .imports: "Import"
        case .claudeCode: "Claude Code"
        }
    }

    public var title: LocalizedStringKey {
        switch self {
        case .forecast: "See where the month will close"
        case .history: "Compare this month with the others"
        case .unusual: "Catch what's out of the ordinary"
        case .future: "See what's already committed"
        case .variance: "Compare plan and reality"
        case .tags: "Follow your spending by tag"
        case .score: "Get a score for your month"
        case .intelligence: "Let Cashly suggest for you"
        case .backups: "Keep a copy without thinking about it"
        case .imports: "Bring in your history"
        case .claudeCode: "Ask Claude about your money"
        }
    }

    public var message: LocalizedStringKey {
        switch self {
        case .forecast:
            "A projection to the end of the month, with how much you can still spend per day."
        case .history:
            "See whether you're spending more or less than usual at this point of the month."
        case .unusual:
            "Categories well above their usual pace show up here before they become a problem."
        case .future:
            "Installments and future bills add up month by month, so none catches you off guard."
        case .variance: "Each category's budget side by side with what actually went out."
        case .tags: "Charts for trips, projects or anything you tag, month after month."
        case .score: "A score from your budgets and spending that shows what to improve."
        case .intelligence:
            "Categories and amounts suggested from your own history, all on this device."
        case .backups:
            "A daily backup on this device or in iCloud Drive, ready to restore when you need it."
        case .imports:
            "Import a backup or a bank spreadsheet and Cashly puts each transaction in place."
        case .claudeCode:
            "Connect Claude Code to read your transactions, run analyses and import statements."
        }
    }

    public var symbol: String {
        switch self {
        case .forecast: "chart.line.uptrend.xyaxis.circle.fill"
        case .history: "calendar.circle.fill"
        case .unusual: "exclamationmark.triangle.fill"
        case .future: "creditcard.fill"
        case .variance: "chart.bar.fill"
        case .tags: "tag.fill"
        case .score: "medal.fill"
        case .intelligence: "bolt.fill"
        case .backups: "externaldrive.fill.badge.timemachine"
        case .imports: "square.and.arrow.down.fill"
        case .claudeCode: "terminal.fill"
        }
    }
}
