import SwiftUI

public enum ProPitch: CaseIterable, Sendable {
    case score, forecast, history, unusual, future, variance, tags
    case backups, imports
    case smartBudget, autoCategories, tagForecast, onDevice
    case askClaude, analyses, statements, approvals

    public var title: LocalizedStringKey {
        switch self {
        case .score: "Get a score for your month"
        case .forecast: "See where the month will close"
        case .history: "Compare this month with the others"
        case .unusual: "Catch what's out of the ordinary"
        case .future: "See what's already committed"
        case .variance: "Compare plan and reality"
        case .tags: "Follow your spending by tag"
        case .backups: "Keep a copy without thinking about it"
        case .imports: "Bring in your history"
        case .smartBudget: "Smart Budget"
        case .autoCategories: "Auto Categorization"
        case .tagForecast: "Tag Forecast"
        case .onDevice: "Learns only on this device"
        case .askClaude: "Ask Claude about your money"
        case .analyses: "Analyses on request"
        case .statements: "Import statements in a conversation"
        case .approvals: "You approve every connection"
        }
    }

    public var message: LocalizedStringKey {
        switch self {
        case .score: "A score from your budgets and spending that shows what to improve."
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
        case .backups:
            "A daily backup on this device or in iCloud Drive, ready to restore when you need it."
        case .imports:
            "Import a backup or a bank spreadsheet and Cashly puts each transaction in place."
        case .smartBudget:
            "Estimates each category's monthly spending from the average of up to six recorded months."
        case .autoCategories:
            "Suggests a category from the words in transactions you've already recorded."
        case .tagForecast: "Predicts each tag's expected monthly spending from your history."
        case .onDevice:
            "The models are trained from your own history and never leave this device."
        case .askClaude:
            "Claude Code reads your transactions, budgets and goals to answer in plain words."
        case .analyses: "Ask for comparisons, trends and summaries of any period."
        case .statements:
            "Share a bank statement with Claude and review every transaction before it's saved."
        case .approvals:
            "Only the connections you allow can read your data, and you can remove them anytime."
        }
    }

    public var symbol: String {
        switch self {
        case .score: "medal.fill"
        case .forecast: "chart.line.uptrend.xyaxis"
        case .history: "calendar"
        case .unusual: "exclamationmark.triangle.fill"
        case .future: "creditcard.fill"
        case .variance: "chart.bar.fill"
        case .tags: "tag.fill"
        case .backups: "externaldrive.fill.badge.timemachine"
        case .imports: "square.and.arrow.down.fill"
        case .smartBudget: "dollarsign.bank.building.fill"
        case .autoCategories: "swatchpalette.fill"
        case .tagForecast: "tag.circle.fill"
        case .onDevice: "lock.shield.fill"
        case .askClaude: "text.bubble.fill"
        case .analyses: "chart.xyaxis.line"
        case .statements: "doc.text.fill"
        case .approvals: "checkmark.shield.fill"
        }
    }
}
