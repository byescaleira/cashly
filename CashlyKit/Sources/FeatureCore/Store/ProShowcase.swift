import SwiftUI

public enum ProShowcase: Sendable {
    case home, data, claudeCode

    public var title: LocalizedStringKey {
        switch self {
        case .home: "Your whole month, explained"
        case .data: "Your data, safe without effort"
        case .claudeCode: "Your money in a conversation"
        }
    }

    public var message: LocalizedStringKey {
        switch self {
        case .home:
            "Recording stays free. With Cashly Pro, Home also scores your month, projects where it will close, explains what changed and where the money goes, and shows what's already committed ahead."
        case .data:
            "Exporting stays free. With Cashly Pro, Cashly keeps backups for you and brings in your history from other files."
        case .claudeCode:
            "With Cashly Pro, Claude Code connects to Cashly on this device to answer questions, run analyses and import statements."
        }
    }

    public var pitches: [ProPitch] {
        switch self {
        case .home:
            [
                .score, .forecast, .variance, .history, .unusual, .changes, .merchants,
                .smallPurchases, .weekdays, .tags, .recurring, .budgetIdeas, .future,
            ]
        case .data: [.backups, .imports]
        case .claudeCode: [.askClaude, .analyses, .statements, .approvals]
        }
    }
}
