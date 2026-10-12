import FeatureCore
import Foundation
import UserNotifications

public final class NotificationResponder: NSObject, UNUserNotificationCenterDelegate,
    @unchecked Sendable
{
    public nonisolated static let shared = NotificationResponder()

    public static func install() {
        UNUserNotificationCenter.current().delegate = shared
        SystemNotifications.registerCategories()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let id = info[NotificationCategory.transactionKey] as? String else {
            await MainActor.run { CashlyServices.shared.pendingURL = URL(string: "cashly://home") }
            return
        }
        switch response.actionIdentifier {
        case NotificationCategory.markPaid:
            _ = try? await actions()?.markPaid(transactionID: id)
        case NotificationCategory.postpone:
            _ = try? await actions()?.postpone(transactionID: id)
        default:
            await MainActor.run {
                CashlyServices.shared.pendingURL = URL(string: "cashly://transactions/\(id)")
            }
        }
    }

    @MainActor
    private func actions() async -> IntentActions? {
        guard await CashlyServices.shared.canWrite(),
            let (repositories, user) = try? await CashlyServices.shared.workspace()
        else { return nil }
        return IntentActions(repositories: repositories, user: user)
    }
}
