//
//  RecurringTransactionTemplateTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("RecurringTransactionTemplate", .tags(.unit, .local))
struct RecurringTransactionTemplateTests {
    /// Locked calendar so month/year arithmetic is reproducible
    /// regardless of CI runner locale or TZ.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func template(
        cadence: RecurringCadence,
        startDate: TimeInterval = 1_704_067_200 // 2024-01-01 UTC
    ) -> RecurringTransactionTemplate {
        RecurringTransactionTemplate(
            summary: "Rent",
            amount: 1200,
            budgetId: "b",
            startDate: startDate,
            cadence: cadence
        )
    }

    @Test("count 0 returns empty")
    func zeroCount() {
        let t = template(cadence: .monthly)
        #expect(t.instances(count: 0, calendar: calendar).isEmpty)
    }

    @Test("first instance equals startDate")
    func firstInstance() {
        let t = template(cadence: .monthly)
        let dates = t.instances(count: 3, calendar: calendar)
        #expect(dates.first == t.startDate)
    }

    @Test("monthly advances by 1 month")
    func monthlyCadence() {
        let t = template(cadence: .monthly)
        let dates = t.instances(count: 3, calendar: calendar)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        #expect(formatter.string(from: Date(timeIntervalSince1970: dates[0])) == "2024-01-01")
        #expect(formatter.string(from: Date(timeIntervalSince1970: dates[1])) == "2024-02-01")
        #expect(formatter.string(from: Date(timeIntervalSince1970: dates[2])) == "2024-03-01")
    }

    @Test("weekly advances by 7 days")
    func weeklyCadence() {
        let t = template(cadence: .weekly)
        let dates = t.instances(count: 2, calendar: calendar)
        let interval = dates[1] - dates[0]
        #expect(Int(interval) == 7 * 24 * 60 * 60)
    }

    @Test("biweekly advances by 14 days")
    func biweeklyCadence() {
        let t = template(cadence: .biweekly)
        let dates = t.instances(count: 2, calendar: calendar)
        let interval = dates[1] - dates[0]
        #expect(Int(interval) == 14 * 24 * 60 * 60)
    }

    @Test("yearly advances by 1 year")
    func yearlyCadence() {
        let t = template(cadence: .yearly)
        let dates = t.instances(count: 2, calendar: calendar)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        #expect(formatter.string(from: Date(timeIntervalSince1970: dates[1])) == "2025-01-01")
    }
}
