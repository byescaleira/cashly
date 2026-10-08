import CashlyDomain

struct SwiftDataCategoryRepository: CategoryRepository {
    let scope: StoreScope

    func category(id: String) async throws -> CashlyDomain.Category? {
        try await scope.store.getCategory(id: id, userID: scope.requireUserID())
    }

    func save(_ category: CashlyDomain.Category) async throws {
        _ = try scope.requireOwner(category.user.id)
        try await scope.store.save(category)
    }

    func delete(id: String) async throws {
        try await scope.store.removeCategory(id: id, userID: scope.requireUserID())
    }
}
