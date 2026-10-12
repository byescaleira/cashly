import CashlyDomain
import SwiftUI

public enum Guide: String, CaseIterable, Identifiable, Sendable {
    case tour, score, importSpreadsheet, budgets, sharing, quickCapture

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tour: String(appLocalized: "Meet Cashly")
        case .score: String(appLocalized: "Health Score")
        case .importSpreadsheet: String(appLocalized: "Import a Spreadsheet")
        case .budgets: String(appLocalized: "Plan the Month")
        case .sharing: String(appLocalized: "Split Expenses")
        case .quickCapture: String(appLocalized: "Record in a Tap")
        }
    }

    public var subtitle: String {
        switch self {
        case .tour: String(appLocalized: "The tabs and what each one shows")
        case .score: String(appLocalized: "What it means and how to raise it")
        case .importSpreadsheet:
            String(appLocalized: "Bring in transactions from another app or spreadsheet")
        case .budgets: String(appLocalized: "Budgets by category and how to follow them")
        case .sharing: String(appLocalized: "Participants, splits and who owes whom")
        case .quickCapture:
            String(appLocalized: "Siri, Control Center, the Action Button and Wallet")
        }
    }

    public var systemImage: String {
        switch self {
        case .tour: "sparkles"
        case .score: "gauge.with.dots.needle.67percent"
        case .importSpreadsheet: "tablecells"
        case .budgets: "chart.pie"
        case .sharing: "person.2"
        case .quickCapture: "bolt"
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
