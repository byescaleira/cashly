import SwiftUI

public enum ProShowcase: Sendable {
    case home, data, intelligence, claudeCode

    public var title: LocalizedStringKey {
        switch self {
        case .home: "Your whole month, explained"
        case .data: "Your data, safe without effort"
        case .intelligence: "A Cashly that learns from you"
        case .claudeCode: "Your money in a conversation"
        }
    }

    public var message: LocalizedStringKey {
        switch self {
        case .home:
            "Recording stays free. With Cashly Pro, Home also scores your month, projects where it will close, compares it with the others and shows what's already committed ahead."
        case .data:
            "Exporting stays free. With Cashly Pro, Cashly keeps backups for you and brings in your history from other files."
        case .intelligence:
            "With Cashly Pro, Cashly trains small models on your own history to fill in budgets, categories and tags for you."
        case .claudeCode:
            "With Cashly Pro, Claude Code connects to Cashly on this device to answer questions, run analyses and import statements."
        }
    }

    public var pitches: [ProPitch] {
        switch self {
        case .home: [.score, .forecast, .history, .unusual, .future, .variance, .tags]
        case .data: [.backups, .imports]
        case .intelligence: [.smartBudget, .autoCategories, .tagForecast, .onDevice]
        case .claudeCode: [.askClaude, .analyses, .statements, .approvals]
        }
    }
}
