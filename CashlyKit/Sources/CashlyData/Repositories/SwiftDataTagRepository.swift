import CashlyDomain

struct SwiftDataTagRepository: TagRepository {
    let scope: StoreScope

    func tag(id: String) async throws -> Tag? {
        try await scope.store.getTag(id: id, userID: scope.requireUserID())
    }

    func save(_ tag: Tag) async throws {
        _ = try scope.requireOwner(tag.user.id)
        try await scope.store.save(tag)
    }

    func delete(id: String) async throws {
        try await scope.store.removeTag(id: id, userID: scope.requireUserID())
    }
}
