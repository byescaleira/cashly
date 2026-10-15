#if DEBUG
    import Foundation

    struct DelayedNotifications: NotificationScheduling {
        static let prefix = "simulation."

        let base: any NotificationScheduling
        let delay: TimeInterval
        let now: @Sendable () -> Date

        func status() async -> NotificationStatus { await base.status() }

        func requestAuthorization() async -> Bool { await base.requestAuthorization() }

        func replace(prefix: String, with reminders: [Reminder]) async {
            for reminder in reminders { await deliver(reminder) }
        }

        func deliver(_ reminder: Reminder) async {
            let id = Self.prefix + reminder.id
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: now().addingTimeInterval(delay))
            await base.replace(
                prefix: id,
                with: [
                    Reminder(
                        id: id, title: reminder.title, body: reminder.body, components: components,
                        category: reminder.category, userInfo: reminder.userInfo,
                        isTimeSensitive: reminder.isTimeSensitive)
                ])
        }

        func registerCaptureActions(_ groups: [CaptureActionGroup]) async {
            await base.registerCaptureActions(groups)
        }

        func setBadge(_ count: Int) async { await base.setBadge(count) }
    }
#endif
