public protocol IntelligenceUseCase: Sendable {
    func models(userID: String) async throws -> [IntelligenceModelInfo]
    func train(userID: String, transactions: [Transaction], tags: [Tag], revision: String)
        async throws -> [IntelligenceModelInfo]
    func predict(userID: String, input: CashlyPredictionInput, revision: String) async throws
        -> CashlyPredictionResult
    func clean(userID: String) async throws
}
