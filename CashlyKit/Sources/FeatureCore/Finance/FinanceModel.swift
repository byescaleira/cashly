import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class FinanceModel {
    public private(set) var isLoading = false
    public private(set) var hasLoaded = false
    public private(set) var allCategories: [CashlyDomain.Category] = []
    public private(set) var categories: [CashlyDomain.Category] = []
    public private(set) var tags: [Tag] = []
    public private(set) var budgets: [Budget] = []
    public private(set) var conflicts: [BudgetConflict] = []
    public private(set) var pendingReferences = 0
    public private(set) var datasetRevision = ""
    public private(set) var totalTransactionCount = 0
    public private(set) var contentGeneration = 0
    public var error: CashlyError?
    var summary = CashlyOverview()
    @ObservationIgnored public var snapshotStore = WidgetSnapshotStore.shared
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private var request = 0

    public init(session: SessionModel) {
        self.session = session
    }

    public var allTags: [Tag] { tags }
    public var hasTransactions: Bool { totalTransactionCount > 0 }
    public var allStatuses: [TransactionStatus] { TransactionStatus.allCases }

    public func load() async {
        request += 1
        let current = request
        let key = session.loadKey
        guard session.user != nil else {
            reset()
            hasLoaded = true
            return
        }
        isLoading = true
        error = nil
        defer {
            if current == request {
                isLoading = false
                hasLoaded = true
            }
        }
        do {
            let state = try await session.repositories.dashboard.load(query: key.query)
            try Task.checkCancellation()
            guard current == request, session.loadKey == key else { return }
            apply(state, query: key.query)
        } catch is CancellationError {} catch {
            if current == request && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }

    public func budgetConflict(categoryID: String, month: YearMonth) async throws
        -> BudgetConflict?
    {
        let catalog = try await session.repositories.dashboard.snapshot(month: month)
        return BudgetConflict.detect(in: catalog.budgets).first {
            $0.categoryID == categoryID && $0.month == month && $0.budgets.count > 1
        }
    }

    @discardableResult
    public func publishSnapshot(month: YearMonth = YearMonth(.now)) async -> WidgetSnapshot? {
        guard let user = session.user else {
            try? snapshotStore?.clear()
            return nil
        }
        let repositories = session.repositories
        guard
            let overview = try? await repositories.dashboard.overview(
                query: TransactionQuery(month: month))
        else { return nil }
        let pending =
            (try? await repositories.dashboard.page(
                query: TransactionQuery(statuses: [.pendingToPay], kinds: [.expense]), after: nil,
                limit: 50
            ).items) ?? []
        let snapshot = WidgetSnapshot(
            user: user, month: month, overview: overview, pending: pending,
            currencyCode: Money.currencyCode)
        try? snapshotStore?.write(snapshot)
        return snapshot
    }

    public func resolveBudgetConflict(keeping id: String) async throws {
        try await session.repositories.budgets.resolveConflict(keeping: id)
        session.reload()
    }

    private func apply(_ state: DashboardState, query: TransactionQuery) {
        allCategories = state.catalog.categories
        categories = allCategories.filter {
            query.categoryIDs.isEmpty || query.categoryIDs.contains($0.id)
        }
        tags = state.catalog.tags
        budgets = state.overview.budgets
        summary = state.overview
        conflicts = state.overview.conflicts
        pendingReferences = max(state.catalog.pendingReferences, state.overview.pendingReferences)
        datasetRevision = state.datasetRevision
        totalTransactionCount = state.totalTransactionCount
        contentGeneration += 1
    }

    private func reset() {
        allCategories = []
        categories = []
        tags = []
        budgets = []
        summary = CashlyOverview()
        conflicts = []
        pendingReferences = 0
        datasetRevision = ""
        totalTransactionCount = 0
    }
}
