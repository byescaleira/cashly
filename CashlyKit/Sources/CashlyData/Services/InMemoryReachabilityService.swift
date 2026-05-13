//
//  InMemoryReachabilityService.swift
//  CashlyKit
//
//  Default-online ReachabilityUseCase for previews, macOS and
//  tests. Tests can flip the tier via `setStatus`.
//

import Foundation
import CashlyDomain

public actor InMemoryReachabilityService: ReachabilityUseCase {
    private var status: ReachabilityStatus
    private var continuations: [UUID: AsyncStream<ReachabilityStatus>.Continuation] = [:]

    public init(initial: ReachabilityStatus = .online) {
        self.status = initial
    }

    public func currentStatus() async -> ReachabilityStatus { status }

    public nonisolated func statusUpdates() -> AsyncStream<ReachabilityStatus> {
        AsyncStream { continuation in
            let id = UUID()
            Task { [weak self] in
                guard let self else { continuation.finish(); return }
                await self.register(id: id, continuation: continuation)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in await self?.unregister(id: id) }
            }
        }
    }

    public func setStatus(_ new: ReachabilityStatus) {
        guard status != new else { return }
        status = new
        for continuation in continuations.values { continuation.yield(new) }
    }

    private func register(
        id: UUID,
        continuation: AsyncStream<ReachabilityStatus>.Continuation
    ) {
        continuations[id] = continuation
        continuation.yield(status)
    }

    private func unregister(id: UUID) {
        continuations[id] = nil
    }
}
