//
//  InMemoryBackgroundRefresh.swift
//  CashlyKit
//
//  Stub BackgroundRefreshUseCase for tests + macOS. Records every
//  schedule call so tests can assert ordering without touching
//  BGTaskScheduler.
//

import Foundation
import CashlyDomain

public actor InMemoryBackgroundRefresh: BackgroundRefreshUseCase {
    public nonisolated let taskIdentifier: String
    public private(set) var scheduledIntervals: [TimeInterval] = []
    public private(set) var registered: Bool = false

    public init(taskIdentifier: String = "com.cashly.tests.refresh") {
        self.taskIdentifier = taskIdentifier
    }

    public func schedule(earliestAfter: TimeInterval) async {
        scheduledIntervals.append(earliestAfter)
    }

    public func register(_ handler: @Sendable @escaping (@Sendable @escaping (Bool) -> Void) -> Void) async {
        registered = true
    }
}
