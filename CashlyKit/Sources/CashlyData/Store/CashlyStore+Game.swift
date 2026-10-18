import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func getGameEvents(userID: String) throws -> [GameEvent] {
        try modelContext.fetch(
            FetchDescriptor<GameEventEntity>(
                predicate: #Predicate { $0.ownerID == userID }, sortBy: [SortDescriptor(\.date)])
        )
        .compactMap { row in
            GameEvent.Kind(rawValue: row.kind).map {
                GameEvent(
                    id: row.id, kind: $0, date: Date(timeIntervalSince1970: row.date),
                    value: row.value, count: row.count)
            }
        }
    }

    public func recordGameEvents(_ events: [GameEvent], userID: String) throws {
        guard try getUser(id: userID) != nil else { throw CashlyError.missingRecord }
        let unique = Set([
            GameEvent.Kind.freezesCredited, .streakRestored, .rerollsCredited, .proMonth,
        ])
        let existing = Set(
            try getGameEvents(userID: userID).filter { unique.contains($0.kind) }.map(\.value))
        for event in events where !(unique.contains(event.kind) && existing.contains(event.value)) {
            insertGameEvent(event, ownerID: userID)
        }
        try commit(userID: userID)
    }

    func insertGameEvent(_ event: GameEvent, ownerID: String) {
        modelContext.insert(
            GameEventEntity(
                id: event.id, ownerID: ownerID, kind: event.kind.rawValue,
                date: event.date.timeIntervalSince1970, value: event.value, count: event.count))
    }
}
