import CashlyDomain

struct SwiftDataDashboardRepository: DashboardRepository {
    let scope: StoreScope

    func snapshot(month: YearMonth?) async throws -> CashlySnapshot {
        guard let userID = scope.userID else {
            return CashlySnapshot(
                users: try await scope.store.getUsers(), currentUser: nil, categories: [],
                budgets: [], tags: [])
        }
        return try await scope.store.catalog(userID: userID, month: month)
    }

    func load(query: TransactionQuery) async throws -> DashboardState {
        try await scope.store.loadDashboard(userID: scope.requireUserID(), query: query)
    }

    func overview(query: TransactionQuery) async throws -> CashlyOverview {
        try await scope.store.overview(userID: scope.requireUserID(), query: query)
    }

    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    {
        try await scope.store.page(
            userID: scope.requireUserID(), query: query, after: cursor, limit: limit)
    }

    func trainingData() async throws -> TrainingDataset {
        try await scope.store.trainingData(userID: scope.requireUserID())
    }

    func datasetRevision() async throws -> String {
        try await scope.store.datasetRevision(userID: scope.requireUserID())
    }
}
