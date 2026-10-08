import CashlyDomain

struct SwiftDataTransactionRepository: TransactionRepository {
    let scope: StoreScope

    func transaction(id: String) async throws -> CashlyDomain.Transaction? {
        try await scope.store.getTransaction(id: id, userID: scope.requireUserID())
    }

    func save(_ transaction: CashlyDomain.Transaction) async throws {
        try await scope.store.save(transaction, userID: scope.requireUserID())
    }

    func delete(id: String) async throws {
        try await scope.store.removeTransaction(id: id, userID: scope.requireUserID())
    }

    func delete(ids: Set<String>) async throws {
        try await scope.store.removeTransactions(ids: ids, userID: scope.requireUserID())
    }
}
