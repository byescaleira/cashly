public protocol TransactionRepository: Sendable {
    func transaction(id: String) async throws -> Transaction?
    func save(_ transaction: Transaction) async throws
    func delete(id: String) async throws
    func delete(ids: Set<String>) async throws
}
