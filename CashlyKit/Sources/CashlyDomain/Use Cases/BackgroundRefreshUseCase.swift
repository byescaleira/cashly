//
//  BackgroundRefreshUseCase.swift
//  CashlyKit
//
//  Contract for the iOS BackgroundTasks scheduler. UI / app
//  delegate calls `schedule` after every foreground fetch so the
//  OS can wake the app off-screen to re-pull when the budget is
//  near its limit. The handler (passed to register) is invoked by
//  the system off the main actor.
//

import Foundation

public protocol BackgroundRefreshUseCase: Sendable {
    /// Identifier the host app registered with the system. Must
    /// match the value in Info.plist `BGTaskSchedulerPermittedIdentifiers`.
    var taskIdentifier: String { get }

    /// Ask the OS to schedule the next refresh. `earliest` is a
    /// hint — the system decides when to fire.
    func schedule(earliestAfter: TimeInterval) async

    /// Register the work the OS calls when it grants the refresh.
    /// `handler` receives a completion closure that MUST be invoked
    /// before the OS budget expires (~30s).
    func register(_ handler: @Sendable @escaping (@Sendable @escaping (Bool) -> Void) -> Void) async
}
