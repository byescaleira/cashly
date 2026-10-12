import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

struct IntentActionsTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private let today = Date(timeIntervalSince1970: 1_790_000_000)

    private func actions() async throws -> (IntentActions, Repositories) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart")
        let fun = CashlyDomain.Category(
            id: "fun", user: owner, name: "Lazer", color: "2A7069", icon: "gamecontroller")
        try await repositories.categories.save(market)
        try await repositories.categories.save(fun)
        try await repositories.budgets.save(
            Budget(
                id: "b-market", money: Money(minorUnits: 50_000), category: market,
                month: YearMonth(today), summary: "Mercado do mês", isConflicted: false))
        let today = today
        return (
            IntentActions(repositories: repositories, user: owner, now: { today }), repositories
        )
    }

    @Test func addsAnExpenseInTheNamedCategory() async throws {
        let (actions, repositories) = try await actions()
        let saved = try await actions.addExpense(
            amount: 45.5, categoryID: "fun", summary: " Cinema ", date: nil)
        #expect(saved.category.id == "fun")
        #expect(saved.money.minorUnits == 4550)
        #expect(saved.summary == "Cinema")
        #expect(saved.date == today)
        #expect(try await repositories.transactions.transaction(id: saved.id) != nil)
    }

    @Test func fallsBackToTheFirstCategoryAndRejectsZero() async throws {
        let (actions, _) = try await actions()
        let saved = try await actions.addExpense(
            amount: 10, categoryID: "missing", summary: "Pão", date: nil)
        #expect(saved.category.name == "Lazer")
        await #expect(throws: CashlyError.self) {
            try await actions.addExpense(amount: 0, categoryID: nil, summary: "", date: nil)
        }
    }

    @Test func summarizesTheMonthAndTheCategory() async throws {
        let (actions, _) = try await actions()
        _ = try await actions.addExpense(amount: 120, categoryID: "market", summary: "", date: nil)
        _ = try await actions.addExpense(amount: 30, categoryID: "fun", summary: "", date: nil)
        let month = try await actions.monthSummary()
        #expect(month.spent.minorUnits == 15_000)
        #expect(month.planned.minorUnits == 50_000)
        #expect(month.available.minorUnits == 35_000)
        let market = try await actions.remaining(categoryID: "market")
        #expect(market.remaining?.minorUnits == 38_000)
        let fun = try await actions.remaining(categoryID: "fun")
        #expect(fun.planned == nil)
        #expect(fun.spent.minorUnits == 3000)
    }

    @Test func listsAndSettlesPendingBills() async throws {
        let (actions, repositories) = try await actions()
        let bill = try await actions.addExpense(
            amount: 80, categoryID: "market", summary: "Luz", date: nil)
        var pending = bill
        pending.status = .pendingToPay
        try await repositories.transactions.save(pending)
        #expect(try await actions.pendingBills().map(\.id) == [bill.id])
        let later = try await actions.postpone(transactionID: bill.id)
        #expect(later.date == today.addingTimeInterval(86_400))
        let paid = try await actions.markPaid(transactionID: bill.id)
        #expect(paid.status == .settled)
        #expect(try await actions.pendingBills().isEmpty)
    }
}
