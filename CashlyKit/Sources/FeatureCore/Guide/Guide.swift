import CashlyDomain
import SwiftUI

public enum Guide: String, CaseIterable, Identifiable, Sendable {
    case tour, recording, sharing, bills, budgets, score, insights, journey
    case widgets, siri, quickCapture, backTap, backups, privacy, importSpreadsheet

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tour: String(appLocalized: "Meet Cashly")
        case .recording: String(appLocalized: "Record an Expense Fast")
        case .sharing: String(appLocalized: "Split with People")
        case .bills: String(appLocalized: "Pending Bills")
        case .budgets: String(appLocalized: "Budgets That Work")
        case .score: String(appLocalized: "Health Score")
        case .insights: String(appLocalized: "Read Your Month")
        case .journey: String(appLocalized: "The Journey")
        case .widgets: String(appLocalized: "Widgets and Lock Screen")
        case .siri: String(appLocalized: "Siri and Shortcuts")
        case .quickCapture: String(appLocalized: "Capture Payments Automatically")
        case .backTap: String(appLocalized: "Double Tap the Back")
        case .backups: String(appLocalized: "Backups, iCloud and Claude Code")
        case .privacy: String(appLocalized: "Privacy")
        case .importSpreadsheet: String(appLocalized: "Import a Spreadsheet")
        }
    }

    public var subtitle: String {
        switch self {
        case .tour: String(appLocalized: "The tabs and what each one shows")
        case .recording: String(appLocalized: "The editor, amounts, categories and tags")
        case .sharing: String(appLocalized: "Participants, split modes and who paid")
        case .bills: String(appLocalized: "Record ahead, get reminded, mark as paid")
        case .budgets: String(appLocalized: "Plan per category and follow the pace")
        case .score: String(appLocalized: "What it means and how to raise it")
        case .insights: String(appLocalized: "What you can spend, forecasts and the unusual")
        case .journey: String(appLocalized: "Levels, streaks, challenges and the shop")
        case .widgets: String(appLocalized: "Your month on the Home Screen and Lock Screen")
        case .siri: String(appLocalized: "The phrases Cashly understands")
        case .quickCapture: String(appLocalized: "Apple Pay to Cashly, one tap to confirm")
        case .backTap: String(appLocalized: "Two taps on your iPhone to add an expense")
        case .backups: String(appLocalized: "Keep your data safe and use it from your Mac")
        case .privacy: String(appLocalized: "Face ID lock, discreet mode and where data lives")
        case .importSpreadsheet:
            String(appLocalized: "Bring in transactions from another app or spreadsheet")
        }
    }

    public var systemImage: String {
        switch self {
        case .tour: "sparkles"
        case .recording: "square.and.pencil"
        case .sharing: "person.2"
        case .bills: "calendar.badge.clock"
        case .budgets: "chart.pie"
        case .score: "gauge.with.dots.needle.67percent"
        case .insights: "lightbulb.max"
        case .journey: "trophy"
        case .widgets: "apps.iphone"
        case .siri: "waveform"
        case .quickCapture: "bolt"
        case .backTap: "hand.tap"
        case .backups: "externaldrive.badge.icloud"
        case .privacy: "lock.shield"
        case .importSpreadsheet: "tablecells"
        }
    }

    public var animation: CashlyAnimation {
        switch self {
        case .tour: .launch
        case .recording: .editor
        case .sharing: .participants
        case .bills: .bills
        case .budgets: .budget
        case .score: .score
        case .insights: .insights
        case .journey: .journey
        case .widgets: .widgets
        case .siri: .siri
        case .quickCapture: .capture
        case .backTap: .editor
        case .backups: .backup
        case .privacy: .privacy
        case .importSpreadsheet: .table
        }
    }

    public var category: GuideCategory {
        switch self {
        case .tour: .start
        case .recording, .sharing, .bills: .recording
        case .budgets, .score: .planning
        case .insights: .analysis
        case .journey: .journey
        case .widgets, .siri, .quickCapture, .backTap: .automation
        case .backups, .privacy, .importSpreadsheet: .data
        }
    }

    public var minutes: Int {
        switch self {
        case .tour, .journey, .quickCapture: 3
        case .score, .importSpreadsheet: 4
        default: 2
        }
    }
}

public struct ShowGuideAction {
    private let action: (Guide) -> Void

    public init(_ action: @escaping (Guide) -> Void) {
        self.action = action
    }

    public func callAsFunction(_ guide: Guide) {
        action(guide)
    }
}

extension EnvironmentValues {
    @Entry public var showGuide: ShowGuideAction?
}
