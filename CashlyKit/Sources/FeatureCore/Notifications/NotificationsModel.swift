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
    }

    public var isAnyOn: Bool { remindsPayments || remindsPlanning }

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
            return "As notificações do Cashly estão desligadas nos ajustes do sistema."
        }
        return
            "Os avisos chegam às 9h no dia de cada conta pendente e no primeiro dia de cada mês."
    }

    public func paymentsKey(userID: String?, generation: Int) -> String {
        "\(remindsPayments):\(userID ?? ""):\(generation)"
    }

    public func refreshStatus() async {
        status = await scheduler.status()
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
            id: Prefix.planning, title: "Planejamento do mês",
            body: "Comece o mês revisando os orçamentos no Cashly.",
            components: DateComponents(day: 1, hour: 9, minute: 0), repeats: true)
    }

    private enum Key {
        static let payments = "cashly.notifications.payments"
        static let planning = "cashly.notifications.planning"
    }

    private enum Prefix {
        static let payment = "payment."
        static let planning = "planning"
    }
}
