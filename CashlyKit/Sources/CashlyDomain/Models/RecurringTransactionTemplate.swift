//
//  RecurringTransactionTemplate.swift
//  CashlyKit
//
//  Plain-value template describing a transaction that should recur
//  on a fixed cadence. The struct is pure — it produces N transaction
//  instances on demand via `instances(from:count:)`. Persistence +
//  scheduling live elsewhere (likely a future RecurringActor +
//  BGTaskScheduler) so the type stays test-friendly.
//

import Foundation

public enum RecurringCadence: String, Sendable, CaseIterable, Codable {
    case weekly
    case biweekly
    case monthly
    case yearly

    /// Calendar component + multiplier used by `Calendar.date(by:value:to:)`.
    public var dateComponent: (component: Calendar.Component, value: Int) {
        switch self {
        case .weekly: return (.weekOfYear, 1)
        case .biweekly: return (.weekOfYear, 2)
        case .monthly: return (.month, 1)
        case .yearly: return (.year, 1)
        }
    }
}

public struct RecurringTransactionTemplate: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public var summary: String
    public var amount: Double
    public var budgetId: String
    public var categoryId: String
    public var startDate: TimeInterval
    public var cadence: RecurringCadence
    public var kind: TransactionKind
    /// Timestamp of the last materialization run. `nil` means the
    /// scheduler has never produced an instance — it'll start from
    /// `startDate` on the next pass.
    public var lastMaterializedAt: TimeInterval?

    public init(
        id: String = UUID().uuidString,
        summary: String,
        amount: Double,
        budgetId: String,
        categoryId: String,
        startDate: TimeInterval,
        cadence: RecurringCadence,
        kind: TransactionKind = .expense,
        lastMaterializedAt: TimeInterval? = nil
    ) {
        self.id = id
        self.summary = summary
        self.amount = amount
        self.budgetId = budgetId
        self.categoryId = categoryId
        self.startDate = startDate
        self.cadence = cadence
        self.kind = kind
        self.lastMaterializedAt = lastMaterializedAt
    }

    /// Returns the next `count` occurrences starting at `startDate`.
    /// Calendar arithmetic — handles month-end / DST consistently
    /// because `Calendar.date(byAdding:value:to:)` normalises.
    public func instances(count: Int, calendar: Calendar = .current) -> [TimeInterval] {
        guard count > 0 else { return [] }
        let base = Date(timeIntervalSince1970: startDate)
        var dates: [TimeInterval] = [startDate]
        let (component, value) = cadence.dateComponent
        for step in 1..<count {
            guard let next = calendar.date(
                byAdding: component,
                value: value * step,
                to: base
            ) else { break }
            dates.append(next.timeIntervalSince1970)
        }
        return dates
    }

    /// K12: returns every occurrence between `lastMaterializedAt`
    /// (or startDate when nil) and `now`, inclusive of `now` if it
    /// hits an exact cadence boundary. Used by the scheduler to
    /// catch up past-due recurrences after the app sat idle.
    public func instancesDue(now: Date = .now, calendar: Calendar = .current) -> [TimeInterval] {
        let lower = lastMaterializedAt ?? startDate
        let cutoff = now.timeIntervalSince1970
        guard lower <= cutoff else { return [] }
        var dates: [TimeInterval] = []
        let (component, value) = cadence.dateComponent
        var step = 0
        // Skip past already-materialized dates.
        let base = Date(timeIntervalSince1970: startDate)
        while true {
            guard let candidate = calendar.date(
                byAdding: component,
                value: value * step,
                to: base
            ) else { break }
            let ts = candidate.timeIntervalSince1970
            if ts > cutoff { break }
            if ts > lower || (lastMaterializedAt == nil && step == 0) {
                dates.append(ts)
            }
            step += 1
            if step > 1_000 { break } // safety
        }
        return dates
    }
}
