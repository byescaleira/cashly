import CashlyData
import CashlyDomain
import Foundation
import Testing

struct GameEventTests {
    @Test func newTransactionsAreRecordedOnce() async throws {
        let db = try await TestDatabase()
        let transaction = try db.transaction("a", cents: 1_000)
        try await db.repositories.transactions.save(transaction)
        try await db.repositories.transactions.save(transaction)
        let events = try await db.repositories.game.events()
        #expect(events.map(\.kind) == [.transactionRecorded])
        #expect(events.first?.value == "a")
        #expect(try await db.friendRepositories.game.events().isEmpty)
    }

    @Test func restoredTransactionsAreNotRecorded() async throws {
        let db = try await TestDatabase()
        try await db.repositories.transactions.save(try db.transaction("a", cents: 1_000))
        let export = try await db.database.backup.export()
        _ = try await db.database.backup.eraseAll()
        #expect(try await db.repositories.game.events().isEmpty)
        try await db.database.backup.restore(export.backup)
        #expect(try await db.repositories.game.events().isEmpty)
    }

    @Test func creditsAndRestoresAreKeptOncePerKey() async throws {
        let db = try await TestDatabase()
        let credit = GameEvent(kind: .freezesCredited, value: "purchase-1", count: 2)
        let note = GameEvent(kind: .noSpendDay)
        try await db.repositories.game.record([credit, note])
        try await db.repositories.game.record([
            GameEvent(kind: .freezesCredited, value: "purchase-1", count: 2),
            GameEvent(kind: .noSpendDay),
        ])
        let events = try await db.repositories.game.events()
        #expect(events.filter { $0.kind == .freezesCredited }.count == 1)
        #expect(events.filter { $0.kind == .noSpendDay }.count == 2)
    }
}
