import CashlyData
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import Testing

@MainActor
struct PresentationFlowTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")
    private let friend = User(id: "friend", name: "Amigo", photo: "2")
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

    @Test func transactionListPaginatesAndDeletes() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        let january = try #require(YearMonth(rawValue: 202_601)).startDate
        for index in 0..<60 {
            try await repositories.transactions.save(
                Transaction(
                    id: String(format: "t%02d", index), participants: [], category: category,
                    money: Money(minorUnits: 100), date: january.addingTimeInterval(Double(index)),
                    summary: "Compra", status: .settled, splitMode: nil, splitValue: nil,
                    paymentsPlan: nil))
        }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        session.filter.startDate = january
        let list = TransactionListModel(session: session)
        await list.load()
        #expect(list.items.count == 50)
        #expect(list.hasMore)
        await list.loadMore()
        #expect(list.items.count == 60)
        #expect(!list.hasMore)
        let first = try #require(list.items.first)
        await list.delete(first)
        await list.load()
        await list.loadMore()
        #expect(list.items.count == 59)
        #expect(!list.items.contains(first))
    }

    @Test func incomeFormCreatesAndEditsWithoutBudget() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        let form = TransactionEditorModel(repositories: repositories)
        await form.load()
        form.draft.kind = .income
        form.draft.date = try #require(YearMonth(rawValue: 202_602)).startDate
        form.draft.amount = 500.02
        form.draft.summary = "Entrada pelo formulário"
        await form.save()
        #expect(form.status.isSaved)
        let saved = try #require(try await repositories.transactions.transaction(id: form.draft.id))
        #expect(saved.kind == .income)
        #expect(saved.money.minorUnits == 50002)

        let edit = TransactionEditorModel(draft: .edit(id: saved.id), repositories: repositories)
        await edit.load()
        #expect(edit.draft.kind == .income)
        edit.draft.amount = 500.03
        await edit.save()
        #expect(edit.status.isSaved)
        let edited = try await repositories.transactions.transaction(id: saved.id)
        #expect(edited?.money.minorUnits == 50003)
    }
}
