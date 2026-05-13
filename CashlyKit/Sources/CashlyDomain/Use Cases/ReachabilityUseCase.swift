//
//  ReachabilityUseCase.swift
//  CashlyKit
//
//  Async-stream-based network reachability contract. UI subscribes
//  to `statusUpdates()` to flip an offline banner on/off. The
//  implementation in CashlyData wraps `NWPathMonitor`.
//

import Foundation

public enum ReachabilityStatus: Sendable, Equatable {
    case online
    case offline
    /// Initial unknown state — UI should treat as online to avoid
    /// flashing a banner during cold start.
    case unknown
}

public protocol ReachabilityUseCase: Sendable {
    func currentStatus() async -> ReachabilityStatus
    func statusUpdates() -> AsyncStream<ReachabilityStatus>
}
