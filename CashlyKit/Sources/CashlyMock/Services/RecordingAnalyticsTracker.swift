//
//  RecordingAnalyticsTracker.swift
//  CashlyKit
//
//  Mock AnalyticsTracker that captures every emitted event in an
//  ordered list so tests can assert on event names and properties.
//

import Foundation
import CashlyResource

public final class RecordingAnalyticsTracker: AnalyticsTracker, @unchecked Sendable {
    public struct Recorded: Sendable, Equatable {
        public let event: String
        public let properties: [String: String]
    }

    private let lock = NSLock()
    private var _events: [Recorded] = []

    public init() {}

    /// Snapshot of the recorded events, taken under the lock. Safe to
    /// read from any actor — the returned array is a value copy and
    /// will not see subsequent writes.
    public var events: [Recorded] {
        lock.lock(); defer { lock.unlock() }
        return _events
    }

    public func track(event: String, properties: [String: String]) {
        lock.lock(); defer { lock.unlock() }
        _events.append(Recorded(event: event, properties: properties))
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        _events.removeAll()
    }
}
