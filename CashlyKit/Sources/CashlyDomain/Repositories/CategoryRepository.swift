public protocol CategoryRepository: Sendable {
    func category(id: String) async throws -> Category?
    func save(_ category: Category) async throws
    func delete(id: String) async throws
}
