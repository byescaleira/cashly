public protocol DashboardUseCase: Sendable {
    func load(query: TransactionQuery) async throws -> DashboardState
    func overview(query: TransactionQuery) async throws -> CashlyOverview
    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    func trainingData() async throws -> TrainingDataset
    func datasetRevision() async throws -> String
    func resolveBudgetConflict(keeping budgetID: String) async throws
}
