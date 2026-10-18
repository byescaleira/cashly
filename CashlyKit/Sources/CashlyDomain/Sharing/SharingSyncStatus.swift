import Foundation

public struct SharingSyncStatus: Hashable, Sendable {
    public enum Phase: Sendable { case idle, syncing, failed }

    public var phase: Phase
    public var lastSync: Date?

    public init(phase: Phase = .idle, lastSync: Date? = nil) {
        self.phase = phase
        self.lastSync = lastSync
    }
}
