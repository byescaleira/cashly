//
//  NWPathReachabilityService.swift
//  CashlyKit
//
//  Network.framework-backed reachability monitor. One actor owns
//  the `NWPathMonitor`; subscribers consume an async stream of
//  status changes.
//

import Foundation
import Network
import CashlyDomain

public actor NWPathReachabilityService: ReachabilityUseCase {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.cashly.reachability")
    private var status: ReachabilityStatus = .unknown
    private var continuations: [UUID: AsyncStream<ReachabilityStatus>.Continuation] = [:]
    private var didStart = false

    public init() {}

    public func currentStatus() async -> ReachabilityStatus {
        if !didStart { start() }
        return status
    }

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

    private func register(
        id: UUID,
        continuation: AsyncStream<ReachabilityStatus>.Continuation
    ) {
        if !didStart { start() }
        continuations[id] = continuation
        continuation.yield(status)
    }

    private func unregister(id: UUID) {
        continuations[id] = nil
    }

    private func start() {
        didStart = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newStatus: ReachabilityStatus = path.status == .satisfied ? .online : .offline
            Task { [weak self] in await self?.publish(newStatus) }
        }
        monitor.start(queue: queue)
    }

    private func publish(_ new: ReachabilityStatus) {
        guard status != new else { return }
        status = new
        for continuation in continuations.values {
            continuation.yield(new)
        }
    }
}
