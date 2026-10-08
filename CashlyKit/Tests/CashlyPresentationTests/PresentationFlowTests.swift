import CashlyData
import CashlyDomain
import CashlyPresentation
import Foundation
import Testing

@MainActor
struct PresentationFlowTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")
    private let friend = User(id: "friend", name: "Amigo", photo: "2")

    private func database() async throws -> CashlyDatabase {
        let database = try CashlyDatabase.open(inMemory: true)
        let users = database.repositories(for: nil).users
        try await users.save(owner)
        try await users.save(friend)
        try await database.repositories(for: owner.id).categories.save(
            Category(id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart"))
        return database
    }

    @Test func windowsKeepIndependentUsers() async throws {
        let database = try await database()
        let january = try #require(YearMonth(rawValue: 202_601)).startDate
        try await database.repositories(for: owner.id).transactions.save(
            Transaction(
                id: "expense",
                participants: [],
                category: Category(
                    id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart"),
                money: Money(minorUnits: 2), date: january, summary: "Compra", status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil))
        let windowA = MainViewModel(provider: database, persistSelection: false)
        let windowB = MainViewModel(provider: database, persistSelection: false)
        await windowA.selectUser(id: owner.id)
        await windowB.selectUser(id: friend.id)
        windowA.filter.startDate = january
        windowB.filter.startDate = january
        await windowA.load()
        await windowB.load()
        #expect(windowA.user?.id == owner.id)
        #expect(windowB.user?.id == friend.id)
        #expect(windowA.expensesAmount == 0.02)
        #expect(windowB.totalTransactionCount == 0)
    }

    @Test func incomeFormCreatesAndEditsWithoutBudget() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        let form = TransactionViewModel(repositories: repositories)
        await form.load()
        form.draft.kind = .income
        form.draft.date = try #require(YearMonth(rawValue: 202_602)).startDate
        form.draft.amount = 500.02
        form.draft.summary = "Entrada pelo formulário"
        await form.save()
        #expect(form.isSaved)
        let saved = try #require(try await repositories.transactions.transaction(id: form.draft.id))
        #expect(saved.kind == .income)
        #expect(saved.money.minorUnits == 50002)

        let edit = TransactionViewModel(draft: .edit(id: saved.id), repositories: repositories)
        await edit.load()
        #expect(edit.draft.kind == .income)
        edit.draft.amount = 500.03
        await edit.save()
        #expect(edit.isSaved)
        let edited = try await repositories.transactions.transaction(id: saved.id)
        #expect(edited?.money.minorUnits == 50003)
    }
}
