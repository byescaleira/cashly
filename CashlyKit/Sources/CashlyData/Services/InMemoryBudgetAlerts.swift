//
//  InMemoryBudgetAlerts.swift
//  CashlyKit
//
//  Stub BudgetAlertsUseCase for previews + tests. Records calls so
//  tests can assert on the schedule order; never touches the
//  real UNUserNotificationCenter.
//

import Foundation
import CashlyDomain

public actor InMemoryBudgetAlerts: BudgetAlertsUseCase {
    public struct Scheduled: Sendable, Equatable {
        public let budgetId: String
        public let summary: String
        public let percentage: Int
    }

    private var permissionGranted: Bool
    private var pending: [String: Scheduled] = [:]

    public init(permissionGranted: Bool = true) {
        self.permissionGranted = permissionGranted
    }

    public var scheduled: [Scheduled] {
        Array(pending.values)
    }

    public func requestPermission() async -> Bool { permissionGranted }

    public func scheduleOvershootAlert(
        budgetId: String,
        budgetSummary: String,
        percentage: Int
    ) async {
        pending[budgetId] = Scheduled(
            budgetId: budgetId,
            summary: budgetSummary,
            percentage: percentage
        )
    }

    public func cancelAll() async {
        pending.removeAll()
    }
}
