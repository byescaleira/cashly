import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@MainActor
struct SessionFlowTests {
    private let owner = User(id: "owner", name: "Perfil")
    private let friend = User(id: "friend", name: "Amigo")
    private var category: CashlyDomain.Category {
        Category(id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
    }

    private func database() async throws -> CashlyDatabase {
        let database = try CashlyDatabase.open(inMemory: true)
        let users = database.repositories(for: nil).users
        try await users.save(owner)
        try await users.save(friend)
        try await database.repositories(for: owner.id).categories.save(category)
        return database
    }

    @Test func windowsKeepIndependentUsers() async throws {
        let database = try await database()
        let january = try #require(YearMonth(rawValue: 202_601)).startDate
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: "expense", participants: [], category: category,
                money: Money(minorUnits: 2), date: january, summary: "Compra", status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil))
        let windowA = SessionModel(provider: database, preference: .disabled)
        let windowB = SessionModel(provider: database, preference: .disabled)
        let financeA = FinanceModel(session: windowA)
        let financeB = FinanceModel(session: windowB)
        await windowA.selectUser(id: owner.id)
        await windowB.selectUser(id: friend.id)
        windowA.filter.startDate = january
        windowB.filter.startDate = january
        await financeA.load()
        await financeB.load()
        #expect(windowA.user?.id == owner.id)
        #expect(windowB.user?.id == friend.id)
        #expect(financeA.expensesAmount == 0.02)
        #expect(financeB.totalTransactionCount == 0)
    }

    @Test func selectingUserResetsFiltersButKeepsPeriod() async throws {
        let database = try await database()
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        let start = try #require(YearMonth(rawValue: 202_603)).startDate
        session.filter.startDate = start
        session.filter.categories = [category]
        let generation = session.generation
        await session.selectUser(id: friend.id)
        #expect(session.user == friend)
        #expect(session.filter.categories.isEmpty)
        #expect(session.filter.startDate == start)
        #expect(session.generation == generation + 1)
    }
}
