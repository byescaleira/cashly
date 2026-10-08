public protocol UserRepository: Sendable {
    func users() async throws -> [User]
    func user(id: String) async throws -> User?
    func save(_ user: User) async throws
    func delete(id: String) async throws
}
