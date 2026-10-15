import CashlyDomain
import Foundation
import Observation

#if canImport(UIKit)
    import UIKit
#endif

@MainActor @Observable
public final class NotificationsModel {
    public private(set) var remindsPayments: Bool
    public private(set) var remindsPlanning: Bool
    public private(set) var remindsBudgets: Bool
    public private(set) var remindsWeekly: Bool
    public private(set) var status: NotificationStatus = .notDetermined
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: any NotificationScheduling

    public init(
        defaults: UserDefaults = .standard,
        scheduler: any NotificationScheduling = SystemNotifications()
    ) {
        self.defaults = defaults
        self.scheduler = scheduler
        remindsPayments = defaults.bool(forKey: Key.payments)
        remindsPlanning = defaults.bool(forKey: Key.planning)
        remindsBudgets = defaults.bool(forKey: Key.budgets)
        remindsWeekly = defaults.bool(forKey: Key.weekly)
    }

    public var isAnyOn: Bool {
        remindsPayments || remindsPlanning || remindsBudgets || remindsWeekly
    }

    public var budgetsToggle: Bool {
        get { remindsBudgets }
        set { Task { await setBudgets(newValue) } }
    }

    public var weeklyToggle: Bool {
        get { remindsWeekly }
        set { Task { await setWeekly(newValue) } }
    }

    public var paymentsToggle: Bool {
        get { remindsPayments }
        set { Task { await setPayments(newValue) } }
    }

    public var planningToggle: Bool {
        get { remindsPlanning }
        set { Task { await setPlanning(newValue) } }
    }

    public var systemSettingsURL: URL? {
        #if os(macOS)
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        #else
            URL(string: UIApplication.openNotificationSettingsURLString)
        #endif
    }

    public var footer: String {
        if status == .denied {
            return String(appLocalized: "Cashly notifications are turned off in system settings.")
        }
        return
            String(
                appLocalized:
                    "Bills remind you at 9 AM on the due day with Mark as Paid and Postpone actions. Budget alerts arrive at 80% and 100%, the summary on Sunday evening and planning on the first day of the month."
            )
    }

    public func paymentsKey(userID: String?, generation: Int) -> String {
        "\(remindsPayments):\(userID ?? ""):\(generation)"
    }

    public func refreshStatus() async {
        status = await scheduler.status()
    }

    public func requestAuthorization() async {
        _ = await allows(true)
    }

    public func setPayments(_ isOn: Bool) async {
        guard await allows(isOn) else { return }
        remindsPayments = isOn
        defaults.set(isOn, forKey: Key.payments)
        if !isOn { await scheduler.replace(prefix: Prefix.payment, with: []) }
    }

    public func setPlanning(_ isOn: Bool) async {
        guard await allows(isOn) else { return }
        remindsPlanning = isOn
        defaults.set(isOn, forKey: Key.planning)
        await scheduler.replace(prefix: Prefix.planning, with: isOn ? [planningReminder] : [])
    }

    public func setBudgets(_ isOn: Bool) async {
        guard await allows(isOn) else { return }
        remindsBudgets = isOn
        defaults.set(isOn, forKey: Key.budgets)
    }

    public func setWeekly(_ isOn: Bool) async {
        guard await allows(isOn) else { return }
        remindsWeekly = isOn
        defaults.set(isOn, forKey: Key.weekly)
        if !isOn { await scheduler.replace(prefix: Prefix.weekly, with: []) }
    }

    public func review(_ snapshot: WidgetSnapshot, now: Date = .now) async {
        if remindsBudgets { await alertBudgets(snapshot) }
        if remindsWeekly { await scheduleWeekly(snapshot, now: now) }
    }

    private func alertBudgets(_ snapshot: WidgetSnapshot) async {
        for line in snapshot.budgets where line.plannedMinorUnits > 0 {
            let used = Double(line.spentMinorUnits) / Double(line.plannedMinorUnits)
            for threshold in [100, 80] where used >= Double(threshold) / 100 {
                let key =
                    "\(Key.budgetAlert).\(line.id).\(snapshot.year)-\(snapshot.month).\(threshold)"
                guard !defaults.bool(forKey: key) else { break }
                defaults.set(true, forKey: key)
                let text = ReminderText.budget(
                    category: line.categoryName,
                    amount: Money(minorUnits: abs(line.remainingMinorUnits)).formatted,
                    isOver: threshold == 100)
                await scheduler.deliver(
                    Reminder(
                        id: key, title: text.title, body: text.body,
                        components: DateComponents(), category: NotificationCategory.budget))
                break
            }
        }
    }

    private func scheduleWeekly(_ snapshot: WidgetSnapshot, now: Date) async {
        let calendar = CashlyCalendar.current
        guard
            let sunday = calendar.nextDate(
                after: now, matching: DateComponents(hour: 18, minute: 0, weekday: 1),
                matchingPolicy: .nextTime)
        else { return }
        let text = ReminderText.weekly(
            spent: Money(minorUnits: snapshot.spentMinorUnits).formatted,
            available: snapshot.plannedMinorUnits > 0
                ? Money(minorUnits: snapshot.availableMinorUnits).formatted : nil)
        await scheduler.replace(
            prefix: Prefix.weekly,
            with: [
                Reminder(
                    id: Prefix.weekly, title: text.title, body: text.body,
                    components: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: sunday),
                    category: NotificationCategory.weekly)
            ])
    }

    public func reviewCaptures(
        for user: User?, repositories: Repositories, categories: [CashlyDomain.Category]
    ) async {
        let notifier = CaptureNotifier(scheduler: scheduler)
        guard let user else {
            await notifier.updateBadge(pending: 0)
            return
        }
        let actions = CaptureActions(repositories: repositories, user: user)
        await notifier.register(
            categories: categories.filter { $0.user.id == user.id },
            frequent: (try? await actions.frequentCategories()) ?? [])
        await notifier.updateBadge(pending: (try? await actions.pending().count) ?? 0)
    }

    public func schedulePayments(for userID: String?, repositories: Repositories) async {
        guard remindsPayments else { return }
        guard let userID else {
            await scheduler.replace(prefix: Prefix.payment, with: [])
            return
        }
        guard
            let page = try? await repositories.dashboard.page(
                query: TransactionQuery(statuses: PaymentSchedule.pendingStatuses), after: nil,
                limit: 200)
        else { return }
        let reminders = PaymentSchedule.upcoming(page.items, after: .now).map {
            $0.reminder(userID: userID)
        }
        await scheduler.replace(prefix: Prefix.payment + userID + ".", with: reminders)
    }

    private func allows(_ isOn: Bool) async -> Bool {
        guard isOn else { return true }
        if await scheduler.status() == .notDetermined {
            _ = await scheduler.requestAuthorization()
        }
        status = await scheduler.status()
        return status == .allowed
    }

    private var planningReminder: Reminder {
        Reminder(
            id: Prefix.planning, title: ReminderText.planning.title,
            body: ReminderText.planning.body,
            components: DateComponents(day: 1, hour: 9, minute: 0), repeats: true,
            category: NotificationCategory.budget)
    }

    private enum Key {
        static let payments = "cashly.notifications.payments"
        static let planning = "cashly.notifications.planning"
        static let budgets = "cashly.notifications.budgets"
        static let weekly = "cashly.notifications.weekly"
        static let budgetAlert = "cashly.notifications.budgetAlert"
    }

    private enum Prefix {
        static let payment = "payment."
        static let planning = "planning"
        static let weekly = "weekly"
    }
}
