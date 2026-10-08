public protocol TagRepository: Sendable {
    func tag(id: String) async throws -> Tag?
    func save(_ tag: Tag) async throws
    func delete(id: String) async throws
}
