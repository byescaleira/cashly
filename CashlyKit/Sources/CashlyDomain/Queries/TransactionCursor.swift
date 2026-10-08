import Foundation

public struct TransactionCursor: Hashable, Sendable {
    public let timestamp: TimeInterval
    public let id: String

    public init(timestamp: TimeInterval, id: String) {
        self.timestamp = timestamp
        self.id = id
    }
}
