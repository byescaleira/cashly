//
//  AnalyticsTrackerTests.swift
//  CashlyKit
//
//  Verify the protocol default `track(event:)` forwards to the
//  two-argument variant and that the NoopAnalyticsTracker is callable
//  without crashing.
//

import Testing
import CashlyResource

@Suite("AnalyticsTracker", .tags(.unit, .data, .local))
struct AnalyticsTrackerTests {

    private final class SpyTracker: AnalyticsTracker, @unchecked Sendable {
        var events: [(String, [String: String])] = []
        func track(event: String, properties: [String: String]) {
            events.append((event, properties))
        }
    }

    @Test("default track(event:) forwards to track(event:properties:) with empty dict")
    func defaultForwardsToTwoArg() {
        let spy = SpyTracker()
        spy.track(event: "ping")
        #expect(spy.events.count == 1)
        #expect(spy.events.first?.0 == "ping")
        #expect(spy.events.first?.1.isEmpty == true)
    }

    @Test("NoopAnalyticsTracker drops events without crashing")
    func noopDrops() {
        let tracker = NoopAnalyticsTracker()
        tracker.track(event: "any", properties: ["k": "v"])
        tracker.track(event: "another")
        // No-op: nothing to assert beyond not crashing.
    }

    @Test("SpyTracker records every event in order")
    func spyRecordsInOrder() {
        let spy = SpyTracker()
        spy.track(event: "first", properties: [:])
        spy.track(event: "second", properties: ["a": "1"])
        spy.track(event: "third")
        #expect(spy.events.map(\.0) == ["first", "second", "third"])
    }
}
