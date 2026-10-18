import CashlyDomain
import FeatureCore
import FeatureTransactions
import Foundation
import Testing

@MainActor
struct CategoryPredictionGateTests {
    private func editor(intelligenceOn: Bool) async throws -> (
        TransactionEditorModel, IntelligenceModel, CashlyDomain.Category
    ) {
        let fixture = try await TransactionFixture()
        let market = Category(
            id: "market", user: fixture.owner, name: "Mercado", color: "0099FF", icon: "cart")
        try await fixture.repositories.categories.save(market)
        var feira = fixture.expense("feira", cents: 5_000, category: market)
        feira.summary = "Feira do bairro"
        var bus = fixture.expense("bus", cents: 500)
        bus.summary = "Ônibus"
        try await fixture.repositories.transactions.save(feira)
        try await fixture.repositories.transactions.save(bus)
        let flags = FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        if intelligenceOn { flags.override(.intelligence, true) }
        let intelligence = IntelligenceModel(session: await fixture.session(), flags: flags)
        await intelligence.load()
        let editor = TransactionEditorModel(repositories: fixture.repositories)
        editor.isPro = true
        await editor.load()
        editor.draft.kind = .expense
        editor.draft.summary = "Feira"
        return (editor, intelligence, market)
    }

    @Test func noPredictionWhileIntelligenceIsOff() async throws {
        let (editor, intelligence, market) = try await editor(intelligenceOn: false)
        let before = editor.draft.category
        await editor.predictCategory(with: intelligence)
        #expect(editor.draft.category == before)
        #expect(editor.draft.category != market)
        #expect(!editor.canEnablePrediction(with: intelligence))
    }

    @Test func predictionWorksWhenIntelligenceIsOn() async throws {
        let (editor, intelligence, market) = try await editor(intelligenceOn: true)
        await editor.predictCategory(with: intelligence)
        #expect(editor.draft.category == market)
    }

    @Test func freeUsersGetNoAutomaticSuggestion() async throws {
        let (editor, intelligence, market) = try await editor(intelligenceOn: true)
        editor.isPro = false
        await editor.predictCategory(with: intelligence)
        #expect(editor.draft.category != market)
    }
}
