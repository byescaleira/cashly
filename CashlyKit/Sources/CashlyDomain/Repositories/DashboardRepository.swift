public protocol DashboardRepository: Sendable {
    func snapshot(month: YearMonth?) async throws -> CashlySnapshot
    func load(query: TransactionQuery) async throws -> DashboardState
    func overview(query: TransactionQuery) async throws -> CashlyOverview
    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    func history() async throws -> TransactionHistory
    func datasetRevision() async throws -> String
}
