import CashlyDomain
import Foundation

extension MainViewModel {
    public func observeChanges() async {
        let stream = provider.changes.changes()
        for await event in stream {
            guard !Task.isCancelled else { return }
            guard event.userID == nil || event.userID == selectedUserID else { continue }
            do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            await load()
        }
    }
    public func load() async {
        revision += 1
        let request = revision
        isLoading = true
        error = nil
        defer { if request == revision { isLoading = false } }
        do {
            let directory = try await provider.repositories(for: nil).users.users()
            try Task.checkCancellation()
            guard request == revision else { return }
            if !hasResolvedInitialUser {
                hasResolvedInitialUser = true
                if persistSelection {
                    let preference = UserDefaults.standard.string(forKey: "cashly.user.id")
                    let old = UserDefaults.standard.data(forKey: "cashly.user").flatMap {
                        try? JSONDecoder().decode(StoredUser.self, from: $0)
                    }
                    selectedUserID = directory.first { $0.id == preference || $0.id == old?.id }?.id
                }
            }
            guard request == revision else { return }
            if !directory.contains(where: { $0.id == selectedUserID }) {
                selectedUserID = directory.first?.id
            }
            users = directory
            guard let userID = selectedUserID else {
                user = nil
                budgets = []
                categories = []
                allCategories = []
                tags = []
                allTags = []
                transactions = []
                summary = CashlyOverview()
                conflicts = []
                pendingReferences = 0
                totalTransactionCount = 0
                nextCursor = nil
                datasetRevision = ""
                return
            }
            let query = query
            let state = try await provider.repositories(for: userID).dashboard.load(
                query: query)
            try Task.checkCancellation()
            guard request == revision, selectedUserID == userID, self.query == query else { return }
            user = state.catalog.currentUser
            users = state.catalog.users
            allCategories = state.catalog.categories
            allTags = state.catalog.tags
            categories = allCategories.filter {
                query.categoryIDs.isEmpty || query.categoryIDs.contains($0.id)
            }
            tags = allTags
            budgets = state.overview.budgets
            transactions = state.page.items
            nextCursor = state.page.nextCursor
            loadedQuery = query
            summary = state.overview
            conflicts = state.overview.conflicts
            pendingReferences = max(
                state.catalog.pendingReferences, state.overview.pendingReferences)
            datasetRevision = state.datasetRevision
            totalTransactionCount = state.totalTransactionCount
            contentGeneration += 1
        } catch is CancellationError {} catch {
            if request == revision && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }
    public func loadMoreTransactions() async {
        guard !isLoading, !isLoadingMore, let cursor = nextCursor, let userID = selectedUserID
        else {
            return
        }
        let request = revision
        let query = loadedQuery
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await provider.repositories(for: userID).dashboard.page(
                query: query, after: cursor, limit: 50)
            try Task.checkCancellation()
            guard request == revision, selectedUserID == userID, self.query == query else { return }
            let present = Set(transactions.map(\.id))
            transactions.append(contentsOf: page.items.filter { !present.contains($0.id) })
            nextCursor = page.nextCursor
            pendingReferences = max(pendingReferences, page.pendingReferences)
        } catch is CancellationError {} catch {
            if request == revision && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }
    public func selectUser(_ user: User) async { await selectUser(id: user.id) }
    public func selectUser(id: String) async {
        revision += 1
        selectionRevision += 1
        let selection = selectionRevision
        guard let value = try? await provider.repositories(for: nil).users.user(id: id) else {
            self.error = .missingRecord
            return
        }
        guard selection == selectionRevision else { return }
        selectedUserID = id
        user = value
        hasResolvedInitialUser = true
        filter = TransactionFilter(
            startDate: filter.startDate, isFilteringByDate: filter.isFilteringByDate)
        transactions = []
        budgets = []
        categories = []
        tags = []
        allCategories = []
        allTags = []
        if persistSelection {
            UserDefaults.standard.set(id, forKey: "cashly.user.id")
            UserDefaults.standard.removeObject(forKey: "cashly.user")
        }
        await load()
    }
    public func trainingData() async throws -> TrainingDataset {
        try await repositories.dashboard.trainingData()
    }
    public func budgetConflict(categoryID: String, month: YearMonth) async throws
        -> BudgetConflict?
    {
        let catalog = try await repositories.dashboard.snapshot(month: month)
        return BudgetConflict.detect(in: catalog.budgets).first {
            $0.categoryID == categoryID && $0.month == month && $0.budgets.count > 1
        }
    }
    public func resolveBudgetConflict(keeping id: String) async throws {
        try await repositories.budgets.resolveConflict(keeping: id)
        await load()
    }
    public func removeTag(_ tag: Tag) async {
        do {
            try await repositories.tags.delete(id: tag.id)
            filter.tags = Set(filter.tags.filter { $0.id != tag.id })
            await load()
        } catch { self.error = error as? CashlyError ?? .onRemove }
    }
    public func removeTransaction(_ transaction: CashlyDomain.Transaction) async {
        do {
            try await repositories.transactions.delete(id: transaction.id)
            await load()
        } catch { self.error = error as? CashlyError ?? .onRemove }
    }
    public func removeTransactions(_ transactions: Set<CashlyDomain.Transaction>) async {
        do {
            try await repositories.transactions.delete(
                ids: Set(transactions.map(\.id)))
            await load()
        } catch { self.error = error as? CashlyError ?? .onRemove }
    }
}

private struct StoredUser: Decodable {
    let id: String
}
