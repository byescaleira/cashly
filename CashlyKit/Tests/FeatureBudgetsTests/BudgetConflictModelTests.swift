import CashlyData
import CashlyDomain
import FeatureBudgets
import FeatureCore
import SwiftData
import Testing

@MainActor
struct BudgetConflictModelTests {
    private let owner = User(id: "owner", name: "Perfil")

    @Test func keepingABudgetResolvesTheConflict() async throws {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let category = Category(
            id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        try await repositories.categories.save(category)
        let month = try #require(YearMonth(rawValue: 202_601))
        try await repositories.budgets.save(
            Budget(
                id: "kept", money: Money(minorUnits: 1000), category: category, month: month,
                summary: "Planejado"))
        let context = ModelContext(database.modelContainer)
        let duplicate = BudgetEntity(
            id: "duplicate", amount: 15, category: "category", date: 202_601, summary: "Outra")
        duplicate.ownerID = owner.id
        duplicate.amountMinorUnits = 1500
        duplicate.amountSource = 15
        context.insert(duplicate)
        try context.save()

        let session = SessionModel(
            provider: CashlyDatabase(modelContainer: database.modelContainer), preference: .disabled
        )
        await session.selectUser(id: owner.id)
        let conflicts = BudgetConflictModel(
            finance: FinanceModel(session: session), categoryID: "category", month: month)
        await conflicts.load()
        #expect(conflicts.conflict?.budgets.count == 2)
        #expect(!conflicts.isLocked)
        let kept = try #require(conflicts.conflict?.budgets.first { $0.id == "kept" })
        #expect(await conflicts.keep(kept))
        await conflicts.load()
        #expect(conflicts.conflict == nil)
        #expect(conflicts.error == nil)
    }
}
