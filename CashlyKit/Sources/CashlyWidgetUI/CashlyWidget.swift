import Foundation

public enum CashlyWidget: String, CaseIterable, Identifiable, Sendable {
    case budget, month, budgets, bills

    public var id: String { rawValue }

    public var kind: String {
        switch self {
        case .budget: "cashly.focus"
        case .month: "cashly.month"
        case .budgets: "cashly.budgets"
        case .bills: "cashly.bills"
        }
    }

    public var sizes: [WidgetSize] {
        switch self {
        case .budget, .month: WidgetSize.supported
        case .budgets: [.medium, .large]
        case .bills: [.small, .medium, .large]
        }
    }

    public var symbol: String {
        switch self {
        case .budget: "scope"
        case .month: "calendar"
        case .budgets: "square.grid.2x2"
        case .bills: "calendar.badge.clock"
        }
    }

    public var url: URL? {
        switch self {
        case .budget, .budgets: URL(string: "cashly://budgets")
        case .month: URL(string: "cashly://home")
        case .bills: nil
        }
    }

    public var followsChoice: Bool { self == .budget }
}
