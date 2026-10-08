public protocol StorageChangeFeed: Sendable {
    func changes() -> AsyncStream<StorageChange>
}
