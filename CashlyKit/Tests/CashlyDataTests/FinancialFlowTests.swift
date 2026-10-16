import CashlyData
import CashlyDomain
import Foundation
import Testing

struct FinancialFlowTests {
    @Test func totalsDoNotDependOnBudgets() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        let overview = try await db.repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        #expect(overview.budgets.isEmpty)
        #expect(overview.expensesTotal.minorUnits == 13335)
        #expect(overview.incomeTotal.minorUnits == 120_005)
        #expect(overview.netTotal.minorUnits == 106_670)
    }

    @Test func budgetsAssociateByCategoryAndMonth() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        let dashboard = db.repositories.dashboard
        try await db.repositories.budgets.save(db.budget("budget", cents: 20000, month: 202_601))
        let january = try await dashboard.overview(query: .init(month: db.month(202_601)))
        #expect(january.budgetExpenses["budget"]?.minorUnits == 13335)

        try await db.repositories.budgets.save(db.budget("budget", cents: 20000, month: 202_602))
        let february = try await dashboard.overview(query: .init(month: db.month(202_602)))
        let march = try await dashboard.overview(query: .init(month: db.month(202_603)))
        #expect(february.budgetExpenses["budget"]?.minorUnits == 3334)
        #expect(march.expensesTotal.minorUnits == 3333)
    }

    @Test func removingBudgetPreservesTransactions() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        try await db.repositories.budgets.save(db.budget("budget", cents: 20000, month: 202_601))
        try await db.repositories.budgets.delete(id: "budget")
        let dashboard = db.repositories.dashboard
        let all = try await dashboard.page(query: .init(), after: nil, limit: 50)
        let income = try await dashboard.page(query: .init(kinds: [.income]), after: nil, limit: 50)
        #expect(all.items.count == 3)
        #expect(income.items.map(\.id) == ["income"])
    }

    @Test func editingDateMovesCompetence() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        try await db.repositories.transactions.save(
            db.transaction("expense", cents: 10001, month: 202_602))
        let overview = try await db.repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        #expect(overview.expensesTotal.minorUnits == 3334)
    }

    @Test func canceledIncomeIsExcluded() async throws {
        let db = try await TestDatabase()
        try await db.saveFlowRecords()
        try await db.repositories.transactions.save(
            db.transaction("income", cents: 120_005, kind: .income, status: .canceled))
        let overview = try await db.repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        #expect(overview.incomeTotal == .zero)
    }
}
