import CashlyData
import CashlyDomain
import Testing

struct RepositoryScopeTests {
    @Test func usersCannotReadOtherUsersRecords() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        let foreign = try await db.friendRepositories.transactions.transaction(id: "income")
        #expect(foreign == nil)
        #expect(try await db.friendRepositories.categories.category(id: "category") == nil)
    }

    @Test func savingForAnotherOwnerFails() async throws {
        let db = try await TestDatabase()
        let foreign = Category(
            id: "foreign", user: db.friend, name: "Outra", color: "000000", icon: "cart")
        await #expect(throws: CashlyError.self) {
            try await db.repositories.categories.save(foreign)
        }
    }

    @Test func scopedOperationsRequireUser() async throws {
        let db = try await TestDatabase()
        let anonymous = db.database.repositories(for: nil)
        await #expect(throws: CashlyError.self) {
            try await anonymous.transactions.transaction(id: "income")
        }
        let snapshot = try await anonymous.dashboard.snapshot(month: nil)
        #expect(snapshot.users.count == 2)
        #expect(snapshot.categories.isEmpty)
    }

    @Test func usersCanOnlyBeRemovedFromTheirOwnScope() async throws {
        let db = try await TestDatabase()
        await #expect(throws: CashlyError.self) {
            try await db.repositories.users.delete(id: db.friend.id)
        }
    }

    @Test func entitiesRoundTrip() async throws {
        let db = try await TestDatabase()
        let tag = Tag(id: "tag", user: db.owner, name: "Feira", color: "00FF00", icon: "tag")
        try await db.repositories.tags.save(tag)
        try await db.repositories.budgets.save(db.budget("budget", cents: 12345, month: 202_601))
        #expect(try await db.repositories.tags.tag(id: "tag") == tag)
        let budget = try await db.repositories.budgets.budget(id: "budget")
        #expect(budget?.money.minorUnits == 12345)
        #expect(budget?.month == (try db.month(202_601)))
        #expect(try await db.repositories.categories.category(id: "category") == db.category)
    }
}
