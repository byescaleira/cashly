#if DEBUG
    import CashlyDomain

    public enum SimulatedNotification: String, CaseIterable, Identifiable, Sendable {
        case bill, budgetWarning, budgetOver, weekly, planning, capture

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .bill: String(appLocalized: "Pending Bill")
            case .budgetWarning, .budgetOver: String(appLocalized: "Budget Alerts")
            case .weekly: String(appLocalized: "Weekly Summary")
            case .planning: String(appLocalized: "Month Planning")
            case .capture: String(appLocalized: "Capture Payment")
            }
        }

        public var symbol: String {
            switch self {
            case .bill: "calendar.badge.clock"
            case .budgetWarning: "gauge.with.dots.needle.67percent"
            case .budgetOver: "exclamationmark.triangle"
            case .weekly: "calendar"
            case .planning: "list.clipboard"
            case .capture: "wallet.pass"
            }
        }
    }
#endif
