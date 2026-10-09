import UserNotifications

public struct SystemNotifications: NotificationScheduling {
    public init() {}

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
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: reminder.components, repeats: reminder.repeats)
            try? await center.add(
                UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }
}
