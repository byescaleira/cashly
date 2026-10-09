import CashlyData
import CashlyDomain
import Foundation
import Testing

struct BackupTests {
    private func filled() async throws -> TestDatabase {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        try await db.repositories.tags.save(
            Tag(id: "tag", user: db.owner, name: "Feira", color: "0099FF", icon: "tag"))
        let participant = Participant(
            id: "party", user: db.friend, splitMode: .equal, splitValue: 2, status: .settled,
            transaction: "shared")
        try await db.repositories.transactions.save(
            db.transaction(
                "shared", cents: 9, plan: 3, participants: [participant], splitValue: 0.05,
                tags: ["tag"]))
        try await db.repositories.budgets.save(db.budget("budget", cents: 20000, month: 202_601))
        return db
    }

    private func records(_ backup: CashlyBackup) -> CashlyBackup {
        var value = backup
        value.exportedAt = .distantPast
        return value
    }

    private func overview(_ db: TestDatabase) async throws -> CashlyOverview {
        try await db.repositories.dashboard.overview(query: .init(month: db.month(202_601)))
    }

    @Test func eraseAndRestoreBringsEverythingBack() async throws {
        let db = try await filled()
        let before = try await overview(db)
        let export = try await db.database.backup.export()
        #expect(export.skipped == 0)
        #expect(export.backup.transactions.count == 4)
        #expect(export.backup.recordCount == 9)

        let erased = try await db.database.backup.eraseAll()
        #expect(Set(erased) == ["owner", "friend"])
        #expect(try await db.database.repositories(for: nil).users.users().isEmpty)

        try await db.database.backup.restore(CashlyBackup(data: export.backup.encoded()))
        let after = try await overview(db)
        #expect(after.expensesTotal == before.expensesTotal)
        #expect(after.incomeTotal == before.incomeTotal)
        #expect(after.budgetExpenses == before.budgetExpenses)
        let again = try await db.database.backup.export()
        #expect(records(again.backup) == records(export.backup))
    }

    @Test func restoringTwiceKeepsOneCopy() async throws {
        let db = try await filled()
        let export = try await db.database.backup.export()
        try await db.database.backup.restore(export.backup)
        try await db.database.backup.restore(export.backup)
        let again = try await db.database.backup.export()
        #expect(records(again.backup) == records(export.backup))
    }

    @Test func sameMonthBudgetBecomesConflict() async throws {
        let db = try await filled()
        let export = try await db.database.backup.export()
        try await db.repositories.budgets.delete(id: "budget")
        try await db.repositories.budgets.save(db.budget("local", cents: 30000, month: 202_601))
        try await db.database.backup.restore(export.backup)
        let snapshot = try await db.repositories.dashboard.snapshot(month: db.month(202_601))
        #expect(snapshot.budgets.count == 2)
        #expect(snapshot.budgets.allSatisfy { $0.isConflicted })
    }

    @Test func invalidRecordLeavesStoreUntouched() async throws {
        let db = try await TestDatabase()
        let other = try await filled()
        var backup = try await other.database.backup.export().backup
        backup.transactions[0].summary = "x"
        await #expect(throws: CashlyError.self) { try await db.database.backup.restore(backup) }
        let users = try await db.database.repositories(for: nil).users.users()
        #expect(users.count == 2)
        #expect(try await db.repositories.tags.tag(id: "tag") == nil)
        #expect(try await overview(db).expensesTotal == .zero)
    }
}
