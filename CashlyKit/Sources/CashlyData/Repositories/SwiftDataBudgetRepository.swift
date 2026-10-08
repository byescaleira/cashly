import CashlyDomain

struct SwiftDataBudgetRepository: BudgetRepository {
    let scope: StoreScope

    func budget(id: String) async throws -> Budget? {
        try await scope.store.getBudget(id: id, userID: scope.requireUserID())
    }

    func save(_ budget: Budget) async throws {
        try await scope.store.save(budget, userID: scope.requireUserID())
    }

    func delete(id: String) async throws {
        try await scope.store.removeBudget(id: id, userID: scope.requireUserID())
    }

    func resolveConflict(keeping id: String) async throws {
        try await scope.store.resolveBudgetConflict(keeping: id, userID: scope.requireUserID())
    }
}
