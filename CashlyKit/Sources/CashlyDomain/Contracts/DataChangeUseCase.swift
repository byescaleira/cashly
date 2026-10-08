public protocol DataChangeUseCase: Sendable {
    func changes() -> AsyncStream<StorageChange>
}
