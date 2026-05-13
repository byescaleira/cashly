//
//  InMemoryBudgetAlertsTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryBudgetAlerts", .tags(.unit, .data, .local))
struct InMemoryBudgetAlertsTests {

    @Test("requestPermission returns the seeded value")
    func permissionGranted() async {
        let granted = InMemoryBudgetAlerts(permissionGranted: true)
        let denied = InMemoryBudgetAlerts(permissionGranted: false)
        #expect(await granted.requestPermission())
        #expect(await denied.requestPermission() == false)
    }

    @Test("schedule stores the alert")
    func scheduleStores() async {
        let service = InMemoryBudgetAlerts()
        await service.scheduleOvershootAlert(
            budgetId: "b1",
            budgetSummary: "Groceries",
            percentage: 90
        )
        let pending = await service.scheduled
        #expect(pending.count == 1)
        #expect(pending.first?.percentage == 90)
        #expect(pending.first?.summary == "Groceries")
    }

    @Test("re-schedule for same budget id replaces the entry")
    func scheduleIdempotent() async {
        let service = InMemoryBudgetAlerts()
        await service.scheduleOvershootAlert(budgetId: "b", budgetSummary: "x", percentage: 80)
        await service.scheduleOvershootAlert(budgetId: "b", budgetSummary: "x", percentage: 95)
        let pending = await service.scheduled
        #expect(pending.count == 1)
        #expect(pending.first?.percentage == 95)
    }

    @Test("cancelAll clears every pending alert")
    func cancelAll() async {
        let service = InMemoryBudgetAlerts()
        await service.scheduleOvershootAlert(budgetId: "a", budgetSummary: "x", percentage: 80)
        await service.scheduleOvershootAlert(budgetId: "b", budgetSummary: "y", percentage: 90)
        await service.cancelAll()
        let pending = await service.scheduled
        #expect(pending.isEmpty)
    }
}
