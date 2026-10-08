import Foundation

public struct TransactionQuery: Hashable, Sendable {
    public var month: Int?
    public var categoryIDs: Set<String>
    public var tagIDs: Set<String>
    public var participantUserIDs: Set<String>
    public var statuses: Set<Int>
    public var kinds: Set<TransactionKind>
    public init(
        month: Int? = nil, categoryIDs: Set<String> = [], tagIDs: Set<String> = [],
        participantUserIDs: Set<String> = [], statuses: Set<Int> = [],
        kinds: Set<TransactionKind> = []
    ) {
        self.month = month
        self.categoryIDs = categoryIDs
        self.tagIDs = tagIDs
        self.participantUserIDs = participantUserIDs
        self.statuses = statuses
        self.kinds = kinds
    }
}
public struct TransactionCursor: Codable, Hashable, Sendable {
    public let date: TimeInterval
    public let id: String
    public init(date: TimeInterval, id: String) {
        self.date = date
        self.id = id
    }
}
public struct TransactionPage: Sendable {
    public let items: [Transaction]
    public let nextCursor: TransactionCursor?
    public let pendingReferences: Int
    public init(items: [Transaction], nextCursor: TransactionCursor?, pendingReferences: Int = 0) {
        self.items = items
        self.nextCursor = nextCursor
        self.pendingReferences = pendingReferences
    }
}
public struct BudgetConflict: Hashable, Identifiable, Sendable {
    public let categoryID: String
    public let month: Int
    public let budgets: [Budget]
    public var id: String { categoryID + "." + String(month) }
    public init(categoryID: String, month: Int, budgets: [Budget]) {
        self.categoryID = categoryID
        self.month = month
        self.budgets = budgets
    }
}
public struct StorageChange: Sendable {
    public let userID: String?
    public let isRemote: Bool
    public init(userID: String? = nil, isRemote: Bool = false) {
        self.userID = userID
        self.isRemote = isRemote
    }
}
public protocol DataChangeUseCase: Sendable {
    func changes() -> AsyncStream<StorageChange>
}
public protocol DashboardUseCase: Sendable {
    func load(query: TransactionQuery) async throws -> DashboardState
    func overview(query: TransactionQuery) async throws -> CashlyOverview
    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    func trainingData() async throws -> TrainingDataset
    func datasetRevision() async throws -> String
    func resolveBudgetConflict(keeping budgetID: String) async throws
}
public struct TrainingDataset: Sendable {
    public let transactions: [Transaction]
    public let tags: [Tag]
    public let revision: String
    public init(transactions: [Transaction], tags: [Tag], revision: String) {
        self.transactions = transactions
        self.tags = tags
        self.revision = revision
    }
}
