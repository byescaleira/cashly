import CashlyDomain

struct SwiftDataGameRepository: GameRepository {
    let scope: StoreScope

    func events() async throws -> [GameEvent] {
        try await scope.store.getGameEvents(userID: scope.requireUserID())
    }

    func record(_ events: [GameEvent]) async throws {
        try await scope.store.recordGameEvents(events, userID: scope.requireUserID())
    }
}
