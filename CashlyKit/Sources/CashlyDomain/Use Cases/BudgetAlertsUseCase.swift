//
//  BudgetAlertsUseCase.swift
//  CashlyKit
//
//  Local-notification scheduling contract for budget overshoot
//  warnings. UI calls `requestPermission()` once on first
//  configuration; the app delegate (or a future middleware) calls
//  `scheduleOvershootAlert(budget:percentage:)` whenever a fetch
//  surfaces a budget at / above the threshold.
//

import Foundation

public protocol BudgetAlertsUseCase: Sendable {
    /// Asks the system for notification permission. Returns the
    /// resolved authorization after the user responds (or the
    /// existing one when permission was already determined).
    func requestPermission() async -> Bool

    /// Schedules a local notification announcing that the user
    /// has crossed the configured spending threshold on a budget.
    /// Idempotent — duplicate calls for the same budget id replace
    /// any pending alert.
    func scheduleOvershootAlert(
        budgetId: String,
        budgetSummary: String,
        percentage: Int
    ) async

    /// Removes every pending Cashly notification — useful on
    /// sign-out / wipe.
    func cancelAll() async
}
