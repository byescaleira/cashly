import CashlyData
import CashlyDomain
import FeatureBudgets
import FeatureCore
import Foundation
import Testing

@MainActor
struct BudgetEditorTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Mercado", color: "0099FF", icon: "cart.fill")
    }

    private func repositories() async throws -> Repositories {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        try await repositories.categories.save(market)
        return repositories
    }

    @Test func newBudgetPicksFirstOwnCategoryAndSaves() async throws {
        let repositories = try await repositories()
        let editor = BudgetEditorModel(repositories: repositories)
        await editor.load()
        #expect(editor.draft.category == market)
        editor.draft.amount = 450.5
        editor.draft.summary = "Compras do mês"
        #expect(editor.canSave)
        await editor.save()
        #expect(editor.status.isSaved)
        let saved = try await repositories.budgets.budget(id: editor.draft.id)
        #expect(saved?.money.minorUnits == 45050)
        #expect(saved?.category == market)
    }

    @Test func zeroAmountOrShortSummaryCannotBeSaved() async throws {
        let editor = BudgetEditorModel(repositories: try await repositories())
        await editor.load()
        editor.draft.summary = "Compras do mês"
        #expect(!editor.canSave)
        editor.draft.amount = 10
        editor.draft.summary = "AB"
        #expect(!editor.canSave)
    }

    @Test func editingLoadsTheBudgetAndAllowsRemoval() async throws {
        let repositories = try await repositories()
        let month = try #require(YearMonth(rawValue: 202_603))
        try await repositories.budgets.save(
            Budget(
                id: "march", money: Money(minorUnits: 100_000), category: market, month: month,
                summary: "Março"))
        let editor = BudgetEditorModel(draft: .edit(id: "march"), repositories: repositories)
        await editor.load()
        #expect(editor.draft.amount == 1000)
        #expect(editor.draft.month == month)
        #expect(editor.canRemove)
        await editor.remove()
        #expect(try await repositories.budgets.budget(id: "march") == nil)
    }
}
