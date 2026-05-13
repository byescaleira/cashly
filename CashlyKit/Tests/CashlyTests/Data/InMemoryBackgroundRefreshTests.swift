//
//  InMemoryBackgroundRefreshTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryBackgroundRefresh", .tags(.unit, .data, .local))
struct InMemoryBackgroundRefreshTests {

    @Test("schedule records the interval")
    func scheduleRecords() async {
        let svc = InMemoryBackgroundRefresh()
        await svc.schedule(earliestAfter: 60)
        await svc.schedule(earliestAfter: 600)
        let intervals = await svc.scheduledIntervals
        #expect(intervals == [60, 600])
    }

    @Test("register flips the flag once")
    func registerFlips() async {
        let svc = InMemoryBackgroundRefresh()
        await svc.register { _ in }
        let registered = await svc.registered
        #expect(registered)
    }

    @Test("taskIdentifier defaults to test-prefixed string")
    func defaultIdentifier() async {
        let svc = InMemoryBackgroundRefresh()
        #expect(svc.taskIdentifier.hasPrefix("com.cashly"))
    }
}
