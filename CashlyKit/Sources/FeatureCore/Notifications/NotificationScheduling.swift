public enum NotificationStatus: Sendable {
    case notDetermined, allowed, denied
}

public protocol NotificationScheduling: Sendable {
    func status() async -> NotificationStatus
    func requestAuthorization() async -> Bool
    func replace(prefix: String, with reminders: [Reminder]) async
}
