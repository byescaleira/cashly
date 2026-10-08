import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class MainViewModel {
    public internal(set) var isLoading = false
    public internal(set) var isLoadingMore = false
    public var filter = TransactionFilter()
    public internal(set) var budgets: [Budget] = []
    public internal(set) var categories: [CashlyDomain.Category] = []
    public internal(set) var transactions: [CashlyDomain.Transaction] = []
    public internal(set) var tags: [Tag] = []
    public internal(set) var users: [User] = []
    public internal(set) var user: User?
    public internal(set) var allCategories: [CashlyDomain.Category] = []
    public internal(set) var allTags: [Tag] = []
    public internal(set) var totalTransactionCount = 0
    public internal(set) var contentGeneration = 0
    public internal(set) var datasetRevision = ""
    public internal(set) var pendingReferences = 0
    public internal(set) var conflicts: [BudgetConflict] = []
    public var hasTransactions: Bool { totalTransactionCount > 0 }
    public var hasMoreTransactions: Bool { nextCursor != nil }
    public var allStatuses: [TransactionStatus] { TransactionStatus.allCases }
    public var error: CashlyError?
    var summary = CashlyOverview()
    @ObservationIgnored let provider: any RepositoryProvider
    @ObservationIgnored let persistSelection: Bool
    @ObservationIgnored var hasResolvedInitialUser = false
    @ObservationIgnored var selectedUserID: String?
    @ObservationIgnored var selectionRevision = 0
    @ObservationIgnored var revision = 0
    @ObservationIgnored var nextCursor: TransactionCursor?
    @ObservationIgnored var loadedQuery = TransactionQuery()
    var repositories: Repositories { provider.repositories(for: selectedUserID) }
    public init(provider: any RepositoryProvider, persistSelection: Bool = true) {
        self.provider = provider
        self.persistSelection = persistSelection
    }
    var query: TransactionQuery {
        TransactionQuery(
            month: filter.isFilteringByDate ? YearMonth(filter.startDate) : nil,
            categoryIDs: Set(filter.categories.map(\.id)), tagIDs: Set(filter.tags.map(\.id)),
            participantUserIDs: Set(filter.participants.map(\.id)),
            statuses: filter.transactionStatuses, kinds: filter.kinds)
    }
}
