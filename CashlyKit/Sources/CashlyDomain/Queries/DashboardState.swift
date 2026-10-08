public struct DashboardState: Sendable {
    public let catalog: CashlySnapshot
    public let overview: CashlyOverview
    public let datasetRevision: String
    public let totalTransactionCount: Int

    public init(
        catalog: CashlySnapshot, overview: CashlyOverview, datasetRevision: String,
        totalTransactionCount: Int
    ) {
        self.catalog = catalog
        self.overview = overview
        self.datasetRevision = datasetRevision
        self.totalTransactionCount = totalTransactionCount
    }
}
