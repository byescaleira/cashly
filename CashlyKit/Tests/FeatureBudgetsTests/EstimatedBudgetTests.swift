import CashlyData
import CashlyDomain
import FeatureBudgets
import FeatureCore
import Foundation
import Testing

@MainActor
struct EstimatedBudgetTests {
    @Test func savingAConvertedBudgetKeepsTheOriginalAmount() async throws {
        let owner = User(id: "owner", name: "Perfil")
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let category = Category(
            id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        try await repositories.categories.save(category)
        let home = Money.currencyCode
        let other = home == "USD" ? "EUR" : "USD"
        CurrencySetting.shared.correction = CurrencyCorrection(
            target: home, date: .now, rates: [other: 5])
        let month = try #require(YearMonth(rawValue: 202_601))
        try await repositories.budgets.save(
            Budget(
                id: "plan", money: Money(minorUnits: 1000), category: category, month: month,
                summary: "Planejado", currencyCode: other))

        let editor = BudgetEditorModel(draft: .edit(id: "plan"), repositories: repositories)
        await editor.load()
        #expect(editor.isAmountLocked)
        #expect(editor.estimateDescription != nil)
        #expect(editor.draft.amount == 50)
        editor.draft.summary = "Planejado de novo"
        await editor.save()
        let saved = try #require(try await repositories.budgets.budget(id: "plan"))
        #expect(saved.summary == "Planejado de novo")
        #expect(saved.estimate?.money == Money(minorUnits: 1000))
        #expect(saved.money == Money(minorUnits: 5000))
    }
}
