import CashlyDomain
import FeatureCore
import Foundation

enum ReminderKind: CaseIterable, Identifiable {
    case payments, budgets, weekly, planning

    var id: Self { self }

    var symbol: String {
        switch self {
        case .payments: "calendar.badge.clock"
        case .budgets: "chart.bar"
        case .weekly: "newspaper"
        case .planning: "calendar"
        }
    }

    var color: RetroColor {
        switch self {
        case .payments: .cherry
        case .budgets: .tangerine
        case .weekly: .denim
        case .planning: .olive
        }
    }

    @MainActor var toggle: ReferenceWritableKeyPath<NotificationsModel, Bool> {
        switch self {
        case .payments: \.paymentsToggle
        case .budgets: \.budgetsToggle
        case .weekly: \.weeklyToggle
        case .planning: \.planningToggle
        }
    }
}

extension NotificationsModel {
    func isOn(_ kind: ReminderKind) -> Bool {
        switch kind {
        case .payments: remindsPayments
        case .budgets: remindsBudgets
        case .weekly: remindsWeekly
        case .planning: remindsPlanning
        }
    }

    var enabledCount: Int { ReminderKind.allCases.filter { isOn($0) }.count }

    func title(of kind: ReminderKind) -> String {
        switch kind {
        case .payments: String(appLocalized: "Bills to Pay and Receive")
        case .budgets: String(appLocalized: "Budget Alerts")
        case .weekly: String(appLocalized: "Weekly Summary")
        case .planning: String(appLocalized: "Month Planning")
        }
    }

    func schedule(of kind: ReminderKind, calendar: Calendar = .current) -> String {
        switch kind {
        case .payments:
            String(appLocalized: "On the due day at \(Self.time(hour: 9, calendar: calendar))")
        case .budgets: String(appLocalized: "Alerts at 80% and 100%")
        case .weekly:
            String(appLocalized: "Sundays at \(Self.time(hour: 18, calendar: calendar))")
        case .planning:
            String(
                appLocalized:
                    "On the first day of the month at \(Self.time(hour: 9, calendar: calendar))")
        }
    }

    func preview(of kind: ReminderKind) -> ReminderText {
        switch kind {
        case .payments:
            ReminderText.bill(
                summary: String(appLocalized: "Electricity"),
                amount: Money(minorUnits: 18_990).formatted, isReceiving: false, installment: 1,
                of: 1)
        case .budgets:
            ReminderText.budget(
                category: String(appLocalized: "Groceries"),
                amount: Money(minorUnits: 6_418).formatted, isOver: false)
        case .weekly:
            ReminderText.weekly(
                spent: Money(minorUnits: 254_300).formatted,
                available: Money(minorUnits: 184_250).formatted)
        case .planning: ReminderText.planning
        }
    }

    func actions(of kind: ReminderKind) -> [String] {
        guard kind == .payments else { return [] }
        return [String(appLocalized: "Mark as Paid"), String(appLocalized: "Postpone 1 Day")]
    }

    var statusSymbol: String {
        switch status {
        case .allowed: enabledCount > 0 ? "bell.badge" : "bell"
        case .denied: "bell.slash"
        case .notDetermined: "bell"
        }
    }

    var statusTitle: String {
        if status == .denied { return String(appLocalized: "Notifications are off") }
        let count = enabledCount
        return count > 0
            ? String(appLocalized: "\(count) of \(ReminderKind.allCases.count) reminders on")
            : String(appLocalized: "No reminders on")
    }

    var permissionTitle: String {
        switch status {
        case .allowed: String(appLocalized: "Allowed")
        case .denied: String(appLocalized: "Off in Settings")
        case .notDetermined: String(appLocalized: "Not asked yet")
        }
    }

    var statusDetail: String {
        switch status {
        case .allowed:
            String(appLocalized: "Cashly can send notifications on this device.")
        case .denied:
            String(appLocalized: "Turn notifications on for Cashly to get the reminders below.")
        case .notDetermined:
            String(appLocalized: "Cashly asks for permission when you turn on the first reminder.")
        }
    }

    var overviewValue: String {
        if status == .denied { return String(appLocalized: "Off in Settings") }
        let count = enabledCount
        if count == 0 { return String(appLocalized: "Off") }
        if count == ReminderKind.allCases.count { return String(appLocalized: "All On") }
        return String(appLocalized: "\(count) of \(ReminderKind.allCases.count) on")
    }

    private static func time(hour: Int, calendar: Calendar) -> String {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: .app))
    }
}
