import CashlyDomain

struct SwiftDataUserRepository: UserRepository {
    let scope: StoreScope

    func users() async throws -> [User] {
        try await scope.store.getUsers()
    }

    func user(id: String) async throws -> User? {
        try await scope.store.getUser(id: id)
    }

    func save(_ user: User) async throws {
        try await scope.store.save(user, contextUserID: scope.userID)
    }

    func delete(id: String) async throws {
        guard id == scope.userID else { throw CashlyError.onRemove }
        try await scope.store.removeUser(id: id)
    }
}
