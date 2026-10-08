public protocol CategoryUseCase: Sendable {
    func getCategory(id: String) async throws -> Category?
    func removeCategory(id: String) async throws
    func addCategory(id: String, user: String, name: String, color: String, icon: String)
        async throws
}
