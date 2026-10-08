public protocol BudgetRepository: Sendable {
    func budget(id: String) async throws -> Budget?
    func save(_ budget: Budget) async throws
    func delete(id: String) async throws
    func resolveConflict(keeping id: String) async throws
}
