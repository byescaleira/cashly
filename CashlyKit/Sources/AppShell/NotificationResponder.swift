import FeatureCore
import FeatureJourney
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
        if let id = info[NotificationCategory.captureKey] as? String {
            await respond(captureID: id, action: response.actionIdentifier)
            return
        }
        if let link = info[NotificationCategory.linkKey] as? String {
            await respond(link: link, action: response.actionIdentifier)
            return
        }
        guard let id = info[NotificationCategory.transactionKey] as? String else {
            await open("cashly://home")
            return
        }
        switch response.actionIdentifier {
        case NotificationCategory.markPaid:
            _ = try? await actions()?.markPaid(transactionID: id)
        case NotificationCategory.postpone:
            _ = try? await actions()?.postpone(transactionID: id)
        default:
            await open("cashly://transactions/\(id)")
        }
    }

    private func respond(captureID: String, action: String) async {
        if action.hasPrefix(NotificationCategory.capturePick) {
            guard let actions = await captureActions() else {
                await open("cashly://captures/\(captureID)")
                return
            }
            let categoryID = String(action.dropFirst(NotificationCategory.capturePick.count))
            _ = try? await actions.accept(captureID: captureID, categoryID: categoryID)
            await updateBadge(actions)
            await JourneyNotifier.reviewInBackground()
        } else if action == NotificationCategory.captureIgnore {
            guard let actions = await captureActions() else { return }
            _ = try? await actions.dismiss(captureID: captureID)
            await updateBadge(actions)
        } else {
            await open("cashly://captures/\(captureID)")
        }
    }

    private func respond(link: String, action: String) async {
        switch action {
        case NotificationCategory.journeyNoSpend: await markNoSpendDay()
        case NotificationCategory.journeyExpense: await open("cashly://transactions/new")
        default: await open(link)
        }
    }

    @MainActor
    private func markNoSpendDay() async {
        guard let (repositories, _) = try? await CashlyServices.shared.workspace() else {
            open(JourneyNotices.journeyLink)
            return
        }
        await JourneyNotifier().markNoSpendDay(repositories: repositories)
    }

    private func updateBadge(_ actions: CaptureActions) async {
        await CaptureNotifier().updateBadge(pending: (try? await actions.pending().count) ?? 0)
    }

    @MainActor
    private func open(_ url: String) {
        CashlyServices.shared.pendingURL = URL(string: url)
    }

    @MainActor
    private func actions() async -> IntentActions? {
        guard let (repositories, user) = try? await CashlyServices.shared.workspace() else {
            return nil
        }
        return IntentActions(repositories: repositories, user: user)
    }

    @MainActor
    private func captureActions() async -> CaptureActions? {
        guard let (repositories, user) = try? await CashlyServices.shared.workspace() else {
            return nil
        }
        return CaptureActions(repositories: repositories, user: user)
    }
}
