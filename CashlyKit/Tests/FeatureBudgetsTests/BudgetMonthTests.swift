import CashlyData
import CashlyDomain
import FeatureBudgets
import FeatureCore
import Foundation
import Testing

@MainActor
struct BudgetMonthTests {
    private let owner = User(id: "owner", name: "Perfil")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Mercado", color: "0099FF", icon: "cart.fill")
    }
    private var home: CashlyDomain.Category {
        Category(id: "home", user: owner, name: "Casa", color: "FF9900", icon: "house")
    }

    private func database() async throws -> CashlyDatabase {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        try await repositories.categories.save(market)
        try await repositories.categories.save(home)
        return database
    }

    private func month(_ raw: Int) throws -> YearMonth {
        try #require(YearMonth(rawValue: raw))
    }

    @Test func monthsWithABudgetAreTakenForThatCategoryOnly() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        try await repositories.budgets.save(
            Budget(
                id: "march", money: Money(minorUnits: 100_000), category: market,
                month: try month(202_603), summary: "Março"))
        let editor = BudgetEditorModel(
            draft: .new(category: market, date: try month(202_603).startDate),
            repositories: repositories)
        await editor.load()
        #expect(editor.takenMonths == [try month(202_603)])
        #expect(editor.isMonthTaken)
        editor.draft.amount = 50
        editor.draft.summary = "Compras"
        #expect(!editor.canSave)
        #expect(editor.monthMessage?.contains("Mercado") == true)
        editor.month = try month(202_604)
        #expect(editor.draft.month == (try month(202_604)))
        #expect(!editor.isMonthTaken)
        #expect(editor.canSave)
        #expect(editor.monthMessage?.contains("Mercado") == true)
        editor.draft.category = home
        #expect(editor.takenMonths.isEmpty)
        #expect(editor.monthMessage == nil)
    }

    @Test func editingABudgetDoesNotBlockItsOwnMonth() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        try await repositories.budgets.save(
            Budget(
                id: "march", money: Money(minorUnits: 100_000), category: market,
                month: try month(202_603), summary: "Março"))
        let editor = BudgetEditorModel(draft: .edit(id: "march"), repositories: repositories)
        await editor.load()
        #expect(editor.takenMonths.isEmpty)
        #expect(editor.canSave)
    }

    @Test func aTakenMonthOpensTheExistingBudget() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        try await repositories.budgets.save(
            Budget(
                id: "march", money: Money(minorUnits: 100_000), category: market,
                month: try month(202_603), summary: "Março"))
        let editor = BudgetEditorModel(
            draft: .new(category: market, date: try month(202_604).startDate),
            repositories: repositories)
        await editor.load()
        #expect(!editor.canEditTakenBudget)
        editor.month = try month(202_603)
        #expect(editor.takenBudgetID == "march")
        #expect(editor.canEditTakenBudget)
        await editor.editTakenBudget()
        #expect(editor.draft.id == "march")
        #expect(!editor.draft.isNew)
        #expect(editor.draft.amount == 1_000)
        #expect(editor.draft.summary == "Março")
        #expect(!editor.isMonthTaken)
        #expect(editor.canSave)
        #expect(editor.canRemove)
    }

    @Test func suggestAmountFollowsTheIntelligenceFlag() async throws {
        let database = try await database()
        let repositories = database.repositories(for: owner.id)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        for (offset, cents) in [(-1, 30_000), (-2, 34_200)] {
            try await repositories.transactions.save(
                Transaction(
                    id: "market\(offset)", participants: [], category: market,
                    money: Money(minorUnits: Int64(cents)),
                    date: YearMonth(.now).adding(months: offset).startDate, summary: "Feira",
                    status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
        }
        let flags = FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        let intelligence = IntelligenceModel(session: session, flags: flags)
        let editor = BudgetEditorModel(repositories: repositories)
        await editor.load()
        editor.draft.category = market
        await intelligence.load()
        #expect(!editor.canSuggestAmount(with: intelligence))
        editor.suggestAmount(with: intelligence)
        #expect(editor.draft.amount == 0)
        flags.override(.intelligence, true)
        await intelligence.load()
        #expect(editor.canSuggestAmount(with: intelligence))
        editor.suggestAmount(with: intelligence)
        #expect(editor.draft.amount == 321)
    }
}
