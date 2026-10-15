import CashlyDomain
import FeatureCore
import FeatureTransactions
import Foundation
import Testing

private struct ClassifyingService: IntelligenceService {
    let categoryID: String

    func models(userID: String) async throws -> [IntelligenceModelInfo] {
        [
            IntelligenceModelInfo(
                kind: .categoryName, updateDate: .now, sampleCount: 5, datasetRevision: "r1")
        ]
    }

    func train(
        userID: String, transactions: [CashlyDomain.Transaction], tags: [CashlyDomain.Tag],
        revision: String
    )
        async throws -> [IntelligenceModelInfo]
    { try await models(userID: userID) }

    func predict(userID: String, input: CashlyPredictionInput, revision: String) async throws
        -> CashlyPredictionResult
    { .textClassification(categoryID) }

    func clean(userID: String) async throws {}
}

@MainActor
struct CategoryPredictionGateTests {
    private func editor(intelligenceOn: Bool) async throws -> (
        TransactionEditorModel, IntelligenceModel, CashlyDomain.Category
    ) {
        let fixture = try await TransactionFixture()
        let market = Category(
            id: "market", user: fixture.owner, name: "Mercado", color: "0099FF", icon: "cart")
        try await fixture.repositories.categories.save(market)
        let flags = FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        if intelligenceOn { flags.override(.intelligence, true) }
        let intelligence = IntelligenceModel(
            service: ClassifyingService(categoryID: market.id), session: await fixture.session(),
            flags: flags)
        await intelligence.loadModels(revision: "r1")
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
