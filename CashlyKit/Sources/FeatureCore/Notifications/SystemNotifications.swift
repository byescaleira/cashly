import UserNotifications

public struct SystemNotifications: NotificationScheduling {
    public init() {}

    public static func registerCategories(captures: [CaptureActionGroup] = []) {
        let paid = UNNotificationAction(
            identifier: NotificationCategory.markPaid,
            title: String(appLocalized: "Mark as Paid"), options: [.authenticationRequired])
        let postpone = UNNotificationAction(
            identifier: NotificationCategory.postpone,
            title: String(appLocalized: "Postpone 1 Day"), options: [.authenticationRequired])
        let noSpend = UNNotificationAction(
            identifier: NotificationCategory.journeyNoSpend,
            title: String(appLocalized: "I Didn't Spend Today"), options: [.authenticationRequired])
        let expense = UNNotificationAction(
            identifier: NotificationCategory.journeyExpense,
            title: String(appLocalized: "New Expense"), options: [.foreground])
        let fixed = [
            UNNotificationCategory(
                identifier: NotificationCategory.bill, actions: [paid, postpone],
                intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.budget, actions: [], intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.weekly, actions: [], intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.journey, actions: [], intentIdentifiers: []),
            UNNotificationCategory(
                identifier: NotificationCategory.journeyStreak, actions: [noSpend, expense],
                intentIdentifiers: []),
        ]
        UNUserNotificationCenter.current().setNotificationCategories(
            Set(fixed + captures.map(Self.category)))
    }

    private static func category(for group: CaptureActionGroup) -> UNNotificationCategory {
        let suggested = group.suggested.map {
            UNNotificationAction(
                identifier: NotificationCategory.capturePick + $0.id, title: "\($0.name) ✓",
                options: [.authenticationRequired])
        }
        let frequent = group.frequent.map {
            UNNotificationAction(
                identifier: NotificationCategory.capturePick + $0.id, title: $0.name,
                options: [.authenticationRequired])
        }
        let other = UNNotificationAction(
            identifier: NotificationCategory.captureOther, title: String(appLocalized: "Other…"),
            options: [.foreground])
        let ignore = UNNotificationAction(
            identifier: NotificationCategory.captureIgnore, title: String(appLocalized: "Ignore"),
            options: [.authenticationRequired])
        return UNNotificationCategory(
            identifier: group.identifier,
            actions: [suggested].compactMap { $0 } + frequent + [other, ignore],
            intentIdentifiers: [])
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

    public func registerCaptureActions(_ groups: [CaptureActionGroup]) async {
        Self.registerCategories(captures: groups)
    }

    public func setBadge(_ count: Int) async {
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
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
