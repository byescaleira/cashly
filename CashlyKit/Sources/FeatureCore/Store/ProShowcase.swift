import SwiftUI

public enum ProShowcase: Sendable {
    case home, data, claudeCode, web

    public var title: LocalizedStringKey {
        switch self {
        case .home: "Your whole month, explained"
        case .data: "Your data, safe without effort"
        case .claudeCode: "Your money in a conversation"
        case .web: "Your month on a computer"
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
        case .web:
            "Recording stays free. With Cashly Pro, scan a QR code on any computer to see this month there, encrypted end to end."
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
        case .web: [.webMonth, .webEncrypted, .webTemporary]
        }
    }
}
