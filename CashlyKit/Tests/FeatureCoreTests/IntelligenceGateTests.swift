import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

private struct TrainedService: IntelligenceService {
    func models(userID: String) async throws -> [IntelligenceModelInfo] {
        CashlyIntelligence.allCases.map {
            IntelligenceModelInfo(
                kind: $0, updateDate: .now, sampleCount: 10, datasetRevision: "r1")
        }
    }

    func train(
        userID: String, transactions: [CashlyDomain.Transaction], tags: [CashlyDomain.Tag],
        revision: String
    )
        async throws -> [IntelligenceModelInfo]
    { try await models(userID: userID) }

    func predict(userID: String, input: CashlyPredictionInput, revision: String) async throws
        -> CashlyPredictionResult
    { .tabularRegression(250) }

    func clean(userID: String) async throws {}
}

@MainActor
struct IntelligenceGateTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func intelligence(flags: FeatureFlags?) async throws -> IntelligenceModel {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        let model = IntelligenceModel(service: TrainedService(), session: session, flags: flags)
        await model.loadModels(revision: "r1")
        return model
    }

    private func flags() -> FeatureFlags {
        FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    }

    @Test func intelligenceIsOffByDefault() async throws {
        #expect(!FeatureFlag.intelligence.defaultValue)
        #expect(!flags().isOn(.intelligence))
        let model = try await intelligence(flags: nil)
        #expect(!model.isEnabled)
        #expect(!model.hasModel(.budgetValue))
        #expect(await model.predict(.text("Mercado")) == .empty)
        #expect(await model.predictExpenses(month: YearMonth(.now), categoryIDs: ["c"]) == 0)
    }

    @Test func turningTheFlagOnUsesTrainedModels() async throws {
        let flags = flags()
        let model = try await intelligence(flags: flags)
        #expect(!model.hasModel(.categoryName))
        flags.override(.intelligence, true)
        #expect(model.isEnabled)
        #expect(model.hasModel(.categoryName))
        #expect(await model.predict(.text("Mercado")) == .tabularRegression(250))
        flags.override(.intelligence, nil)
        #expect(!model.hasModel(.categoryName))
    }
}
