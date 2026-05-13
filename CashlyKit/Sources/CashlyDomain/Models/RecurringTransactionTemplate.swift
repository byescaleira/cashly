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
    public var startDate: TimeInterval
    public var cadence: RecurringCadence

    public init(
        id: String = UUID().uuidString,
        summary: String,
        amount: Double,
        budgetId: String,
        startDate: TimeInterval,
        cadence: RecurringCadence
    ) {
        self.id = id
        self.summary = summary
        self.amount = amount
        self.budgetId = budgetId
        self.startDate = startDate
        self.cadence = cadence
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
}
