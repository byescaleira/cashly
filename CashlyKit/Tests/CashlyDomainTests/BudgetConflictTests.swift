import CashlyDomain
import Testing

struct BudgetConflictTests {
    private let owner = User(id: "owner", name: "Owner", photo: "")

    private func budget(_ id: String, category: String, month: Int, conflicted: Bool) throws
        -> Budget
    {
        Budget(
            id: id, money: Money(minorUnits: 100),
            category: Category(id: category, user: owner, name: category, color: "", icon: ""),
            month: try #require(YearMonth(rawValue: month)), summary: "Plano",
            isConflicted: conflicted)
    }

    @Test func groupsConflictedBudgetsByCategoryAndMonth() throws {
        let conflicts = BudgetConflict.detect(in: [
            try budget("b2", category: "food", month: 202_601, conflicted: true),
            try budget("b1", category: "food", month: 202_601, conflicted: true),
            try budget("b3", category: "food", month: 202_602, conflicted: true),
            try budget("b4", category: "home", month: 202_601, conflicted: false),
        ])
        #expect(conflicts.map(\.id) == ["food.202601", "food.202602"])
        #expect(conflicts.first?.budgets.map(\.id) == ["b1", "b2"])
    }

    @Test func ignoresBudgetsWithoutConflict() throws {
        let conflicts = BudgetConflict.detect(in: [
            try budget("b1", category: "food", month: 202_601, conflicted: false)
        ])
        #expect(conflicts.isEmpty)
    }
}
