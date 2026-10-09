import CoreData
import Foundation

extension CashlyDatabase {
    public static func syncEvents() -> AsyncStream<Date> {
        AsyncStream { continuation in
            nonisolated(unsafe) let observer = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil,
                queue: nil
            ) { notification in
                guard
                    let event = notification.userInfo?[
                        NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event,
                    event.type != .setup, event.succeeded, let end = event.endDate
                else { return }
                continuation.yield(end)
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
