import SwiftUI

public enum ProPitch: CaseIterable, Sendable {
    case score, forecast, history, unusual, changes, merchants, smallPurchases, weekdays
    case recurring, budgetIdeas, future, variance, tags
    case backups, imports
    case askClaude, analyses, statements, approvals

    public var title: LocalizedStringKey {
        switch self {
        case .score: "Get a score for your month"
        case .forecast: "See where the month will close"
        case .history: "Compare this month with the others"
        case .unusual: "Catch what's out of the ordinary"
        case .changes: "Understand what changed"
        case .merchants: "See what you buy again and again"
        case .smallPurchases: "See small purchases add up"
        case .weekdays: "Spot your biggest day"
        case .recurring: "Review what charges you every month"
        case .budgetIdeas: "Know which budgets to create"
        case .future: "See what's already committed"
        case .variance: "Compare plan and reality"
        case .tags: "Follow your spending by tag"
        case .backups: "Keep a copy without thinking about it"
        case .imports: "Bring in your history"
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
        case .changes:
            "Whether a category went up because you bought more often or paid more each time."
        case .merchants: "The purchases you repeat most, with what they cost per month."
        case .smallPurchases:
            "Coffees and snacks are small one by one. See what they add up to in a year."
        case .weekdays:
            "Your average spending on each day of the week, to see which one weighs most."
        case .recurring:
            "Subscriptions and fixed bills found in your history, with what they cost in a year."
        case .budgetIdeas:
            "Categories you spend on every month without a plan, with a suggested amount."
        case .future:
            "Installments and future bills add up month by month, so none catches you off guard."
        case .variance: "Each category's budget side by side with what actually went out."
        case .tags: "Charts for trips, projects or anything you tag, month after month."
        case .backups:
            "A daily backup on this device or in iCloud Drive, ready to restore when you need it."
        case .imports:
            "Import a backup or a bank spreadsheet and Cashly puts each transaction in place."
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
        case .changes: "arrow.up.arrow.down"
        case .merchants: "repeat"
        case .smallPurchases: "cup.and.saucer.fill"
        case .weekdays: "calendar.day.timeline.left"
        case .recurring: "dollarsign.arrow.circlepath"
        case .budgetIdeas: "chart.pie.fill"
        case .future: "creditcard.fill"
        case .variance: "chart.bar.fill"
        case .tags: "tag.fill"
        case .backups: "externaldrive.fill.badge.timemachine"
        case .imports: "square.and.arrow.down.fill"
        case .askClaude: "text.bubble.fill"
        case .analyses: "chart.xyaxis.line"
        case .statements: "doc.text.fill"
        case .approvals: "checkmark.shield.fill"
        }
    }
}
