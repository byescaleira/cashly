import UserNotifications

public struct SystemNotifications: NotificationScheduling {
    public init() {}

    public static func registerCategories() {
        let paid = UNNotificationAction(
            identifier: NotificationCategory.markPaid,
            title: String(appLocalized: "Mark as Paid"), options: [.authenticationRequired])
        let postpone = UNNotificationAction(
            identifier: NotificationCategory.postpone,
            title: String(appLocalized: "Postpone 1 Day"), options: [.authenticationRequired])
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(
                identifier: NotificationCategory.bill, actions: [paid, postpone],
                intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.budget, actions: [], intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.weekly, actions: [], intentIdentifiers: []),
        ])
    }

    public func status() async -> NotificationStatus {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    public func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ])) ?? false
    }

    public func replace(prefix: String, with reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let stale = await center.pendingNotificationRequests().map(\.identifier).filter {
            $0.hasPrefix(prefix)
        }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for reminder in reminders {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: reminder.components, repeats: reminder.repeats)
            try? await center.add(
                UNNotificationRequest(
                    identifier: reminder.id, content: Self.content(for: reminder), trigger: trigger)
            )
        }
    }

    public func deliver(_ reminder: Reminder) async {
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: reminder.id, content: Self.content(for: reminder), trigger: nil))
    }

    private static func content(for reminder: Reminder) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = reminder.category
        content.userInfo = reminder.userInfo
        content.interruptionLevel = reminder.isTimeSensitive ? .timeSensitive : .active
        return content
    }
}
