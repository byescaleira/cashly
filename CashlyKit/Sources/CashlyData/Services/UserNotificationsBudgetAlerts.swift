//
//  UserNotificationsBudgetAlerts.swift
//  CashlyKit
//
//  UserNotifications-backed BudgetAlertsUseCase. iOS / macOS / visionOS
//  all carry the framework, so no platform switch needed here.
//

import Foundation
import UserNotifications
import CashlyDomain

public actor UserNotificationsBudgetAlerts: BudgetAlertsUseCase {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    public func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func scheduleOvershootAlert(
        budgetId: String,
        budgetSummary: String,
        percentage: Int
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Cashly"
        content.body = String(
            format: NSLocalizedString(
                "You've spent %lld%% of your %@ budget.",
                bundle: .main,
                comment: ""
            ),
            percentage,
            budgetSummary
        )
        content.sound = .default

        // Fire ~5s later — gives the dispatch loop time to settle so
        // the alert lands after the UI has actually updated. Tests
        // can replace this whole service with a stub.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "cashly.budget.overshoot.\(budgetId)",
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
        do {
            try await center.add(request)
        } catch {
            // Best-effort — a notification failing to schedule is not
            // worth crashing for. Future work: surface via analytics.
        }
    }

    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}
