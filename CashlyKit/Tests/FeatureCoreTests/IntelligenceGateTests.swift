import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@MainActor
struct IntelligenceGateTests {
    private let owner = User(id: "owner", name: "Perfil")

    private func intelligence(flags: FeatureFlags?) async throws -> IntelligenceModel {
        try await setup(flags: flags).0
    }

    private func setup(flags: FeatureFlags?) async throws -> (
        IntelligenceModel, SessionModel
    ) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = Category(
            id: "market", user: owner, name: "Mercado", color: "0099FF", icon: "cart")
        let transport = Category(
            id: "transport", user: owner, name: "Transporte", color: "FF9900", icon: "bus")
        try await repositories.categories.save(market)
        try await repositories.categories.save(transport)
        for (id, category, summary, offset) in [
            ("a", market, "Mercado do bairro", -1), ("b", market, "Mercado", -2),
            ("c", transport, "Ônibus", -1),
        ] {
            try await repositories.transactions.save(
                Transaction(
                    id: id, participants: [], category: category, money: Money(minorUnits: 10_000),
                    date: YearMonth(.now).adding(months: offset).startDate, summary: summary,
                    status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
        }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        let model = IntelligenceModel(session: session, flags: flags)
        await model.load()
        return (model, session)
    }

    private func flags() -> FeatureFlags {
        FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    }

    @Test func intelligenceIsOffByDefault() async throws {
        #expect(!FeatureFlag.intelligence.defaultValue)
        #expect(!flags().isOn(.intelligence))
        let model = try await intelligence(flags: nil)
        #expect(!model.isEnabled)
        #expect(!model.canSuggestBudget)
        #expect(model.category(for: "Mercado") == nil)
        #expect(model.budget(categoryID: "market", month: YearMonth(.now)) == nil)
    }

    @Test func turningTheFlagOnSuggestsFromTheHistory() async throws {
        let flags = flags()
        flags.override(.intelligence, true)
        let model = try await intelligence(flags: flags)
        #expect(model.canSuggestCategory)
        #expect(model.category(for: "mercado central") == "market")
        #expect(model.budget(categoryID: "market", month: YearMonth(.now)) == 100)
        flags.override(.intelligence, nil)
        #expect(!model.canSuggestCategory)
        #expect(model.category(for: "mercado central") == nil)
    }

    @Test func turningTheFlagOnLaterChangesTheKeyAndLoads() async throws {
        let flags = flags()
        let (model, _) = try await setup(flags: flags)
        let before = model.key(revision: "r1")
        #expect(!model.canSuggestBudget)
        flags.override(.intelligence, true)
        #expect(model.key(revision: "r1") != before)
        await model.load()
        #expect(model.canSuggestBudget)
    }

    @Test func switchingProfileDropsTheSuggestions() async throws {
        let flags = flags()
        flags.override(.intelligence, true)
        let (model, session) = try await setup(flags: flags)
        #expect(model.canSuggestCategory)
        try await session.repositories.users.save(User(id: "friend", name: "Amigo"))
        await session.refreshUsers()
        await session.selectUser(id: "friend")
        await model.load()
        #expect(!model.canSuggestCategory)
        #expect(model.category(for: "mercado") == nil)
    }
}
