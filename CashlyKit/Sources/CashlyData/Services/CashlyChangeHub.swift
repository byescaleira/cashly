import CashlyDomain
import CoreData
import Foundation

/// NSLock protects all mutable state; callbacks never access a ModelContext.
public final class CashlyChangeHub: @unchecked Sendable, DataChangeUseCase {
    private let lock = NSLock()
    private var revision: UInt64 = 0
    public var remoteRevision: UInt64 { lock.withLock { revision } }
    private var listeners: [UUID: AsyncStream<StorageChange>.Continuation] = [:]
    private var observer: (any NSObjectProtocol)?
    public init() {
        observer = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil
        ) { [weak self] _ in
            self?.publish(StorageChange(isRemote: true))
        }
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    public func changes() -> AsyncStream<StorageChange> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            lock.withLock { listeners[id] = continuation }
            continuation.onTermination = { [weak self] _ in self?.remove(id) }
        }
    }
    private func remove(_ id: UUID) { _ = lock.withLock { listeners.removeValue(forKey: id) } }
    public func publish(_ change: StorageChange) {
        let current = lock.withLock {
            if change.isRemote { revision &+= 1 }
            return Array(listeners.values)
        }
        // A coalesced signal invalidates all windows so a later event for another user
        // cannot hide a prior change for this window in bufferingNewest(1).
        let invalidation = StorageChange(isRemote: change.isRemote)
        for listener in current { listener.yield(invalidation) }
    }
}
