public protocol GameRepository: Sendable {
    func events() async throws -> [GameEvent]
    func record(_ events: [GameEvent]) async throws
}
