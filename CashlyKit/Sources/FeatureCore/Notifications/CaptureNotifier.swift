import CashlyDomain

public struct CaptureNotifier: Sendable {
    private let scheduler: any NotificationScheduling

    public init(scheduler: any NotificationScheduling = SystemNotifications()) {
        self.scheduler = scheduler
    }

    public func register(categories: [CashlyDomain.Category], frequent: [CashlyDomain.Category])
        async
    {
        await scheduler.registerCaptureActions(
            CaptureActionGroup.groups(categories: categories, frequent: frequent))
    }

    public func notify(_ capture: Capture, categories: [CashlyDomain.Category]) async {
        await scheduler.deliver(capture.reminder(categories: categories))
    }

    public func updateBadge(pending: Int) async {
        await scheduler.setBadge(pending)
    }
}
