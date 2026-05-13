//
//  BGTaskBackgroundRefresh.swift
//  CashlyKit
//
//  BackgroundTasks-framework backed implementation. macOS branch
//  falls back to a no-op (BGAppRefreshTask isn't available there).
//

import Foundation
import CashlyDomain
#if os(iOS) || os(tvOS) || os(visionOS)
import BackgroundTasks
#endif

public actor BGTaskBackgroundRefresh: BackgroundRefreshUseCase {
    public nonisolated let taskIdentifier: String

    public init(taskIdentifier: String = "com.cashly.app.refresh") {
        self.taskIdentifier = taskIdentifier
    }

    public func schedule(earliestAfter seconds: TimeInterval) async {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }

    public func register(_ handler: @Sendable @escaping (@Sendable @escaping (Bool) -> Void) -> Void) async {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let id = taskIdentifier
        BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: nil) { task in
            handler { success in
                task.setTaskCompleted(success: success)
            }
        }
        #endif
    }
}
