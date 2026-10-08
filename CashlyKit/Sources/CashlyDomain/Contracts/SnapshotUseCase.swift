public protocol SnapshotUseCase: Sendable {
    func snapshot(month: YearMonth?) async throws -> CashlySnapshot
}

extension SnapshotUseCase {
    public func snapshot() async throws -> CashlySnapshot { try await snapshot(month: nil) }
}
