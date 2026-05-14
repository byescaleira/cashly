//
//  MainMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import CashlyResource
import PrismArchitecture
import Foundation

private actor PredictionCache {
    var budgetValue: CashlyPrediction?
    var categoryName: CashlyPrediction?
    var tagValue: CashlyPrediction?
    /// Id of the user the current predictions were built for. The
    /// cache must invalidate on user switch — otherwise the next
    /// fetch runs predictions from User A against User B's data.
    var cachedUserId: String?

    func isReady(user: User?) async -> Bool {
        if cachedUserId != user?.id {
            invalidate()
        }
        guard budgetValue != nil, categoryName != nil, tagValue != nil
        else { return await setup(user: user) }
        return true
    }

    func setup(user: User?) async -> Bool {
        if cachedUserId != user?.id {
            invalidate()
        }
        guard let user,
              let budgetValueModel = CashlyIntelligence.budgetValue.model(for: user),
              let categoryNameModel = CashlyIntelligence.categoryName.model(for: user),
              let tagValueModel = CashlyIntelligence.tagValue.model(for: user)
        else { return false }

        budgetValue = await CashlyPrediction(model: budgetValueModel)
        categoryName = await CashlyPrediction(model: categoryNameModel)
        tagValue = await CashlyPrediction(model: tagValueModel)
        cachedUserId = user.id
        return true
    }

    func invalidate() {
        budgetValue = nil
        categoryName = nil
        tagValue = nil
        cachedUserId = nil
    }

    func prediction(input: CashlyPredictionInput, model: CashlyIntelligence) async -> CashlyPredictionResult {
        guard let budgetValue, let categoryName, let tagValue else { return .empty }
        switch model {
        case .budgetValue: return await budgetValue.regressionPrediction(from: input)
        case .categoryName: return await categoryName.textPrediction(from: input)
        case .tagValue: return await tagValue.regressionPrediction(from: input)
        }
    }
}

public struct MainMiddleware: PrismMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase
    let userPreferences: UserPreferencesUseCase
    let budgetAlerts: BudgetAlertsUseCase
    let spotlight: SpotlightIndexerUseCase
    let watchSync: WatchSyncUseCase
    /// Fraction of a budget's amount at which the overshoot alert
    /// fires. 0.8 = 80%. Wave G11 will hoist this into UserDefaults
    /// so the user can tune the trip-wire.
    let overshootThreshold: Double
    private let cache = PredictionCache()

    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        tagUseCase: TagUseCase,
        userUseCase: UserUseCase,
        userPreferences: UserPreferencesUseCase,
        budgetAlerts: BudgetAlertsUseCase,
        spotlight: SpotlightIndexerUseCase,
        watchSync: WatchSyncUseCase,
        overshootThreshold: Double = 0.8
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
        self.userPreferences = userPreferences
        self.budgetAlerts = budgetAlerts
        self.spotlight = spotlight
        self.watchSync = watchSync
        self.overshootThreshold = overshootThreshold
    }

    public func run(state: MainState, action: MainAction) -> PrismEffect<MainAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case let .update(_, budgets, _, transactions, _, _, user, _):
            // K7c: fire-and-forget snapshot to the paired Watch.
            // Silent no-op when no Watch is paired. Runs alongside
            // the overshoot-alert effect below.
            let snapshot = Self.snapshot(transactions: transactions, user: user)
            let watchSyncRef = watchSync
            Task { await watchSyncRef.send(snapshot) }
            // Scan freshly-loaded budgets vs their transactions and
            // schedule overshoot alerts. The use case is idempotent
            // per budget id, so re-running on every fetch is safe —
            // no duplicate notifications land.
            return scheduleOvershootAlerts(budgets: budgets, transactions: transactions)
        case let .removeTag(tag): return removeTag(tag: tag)
        case let .removeTransaction(transaction): return removeTransaction(transaction: transaction)
        case let .removeTransactions(transactions): return removeTransactions(transactions: transactions)
        case .selectUser: return selectUser(state: state)
        case .fetchPredictions: return fetchPredictions(state: state)
        case .wipeAllData: return wipeAllData()
        case let .settleLoan(tx): return settleLoan(transaction: tx)
        case let .importCSV(url): return importCSV(url: url, state: state)
        case let .reorderCategories(ids): return reorderCategories(ids: ids)
        case .subscriptionUpdated, .reachabilityUpdated, .syncStatusUpdated,
             .error, .stopLoading, .csvImportFinished, .replace: return .none
        }
    }

    private func fetch(state: MainState) -> PrismEffect<MainAction> {
        .run { send in
            await CashlySignpost.withInterval("MainMiddleware.fetch") {
                await Self.fetchBody(state: state, send: send, deps: self)
            }
        }
    }

    private static func fetchBody(
        state: MainState,
        send: @Sendable (MainAction) -> Void,
        deps: MainMiddleware
    ) async {
        let userUseCase = deps.userUseCase
        let categoryUseCase = deps.categoryUseCase
        let budgetUseCase = deps.budgetUseCase
        let tagUseCase = deps.tagUseCase
        let transactionUseCase = deps.transactionUseCase
        let cache = deps.cache
            do {
                let user = try await userUseCase.getCurrentUser()
                let userFilter = user == nil ? nil : [user?.id ?? ""]

                let allCategories = try await categoryUseCase.getCategories(ids: nil, users: userFilter)
                let allBudgets = try await budgetUseCase.getBudgets(categories: allCategories.map(\.id), date: nil)
                // `tags` was previously fetched twice (allTags + tags) — same
                // query, same args. Fetch once, reuse for both filter chrome
                // and the .update payload.
                async let allTagsTask = tagUseCase.getTags(users: userFilter)
                async let allTransactions = transactionUseCase.getTransactions(
                    budgets: allBudgets.map(\.id), tags: nil, statuses: nil, participants: nil, date: nil
                )

                let date: Date? = !state.filter.isFilteringByDate ? nil : state.filter.startDate
                async let users = userUseCase.getUsers()

                let categories = try await categoryUseCase.getCategories(
                    ids: state.filter.categories.isEmpty ? nil : state.filter.categories.map(\.id),
                    users: userFilter
                )
                let budgets = try await budgetUseCase.getBudgets(
                    categories: categories.map(\.id), date: date
                )
                async let transactions = transactionUseCase.getTransactions(
                    budgets: budgets.map(\.id),
                    tags: state.filter.tags.isEmpty ? nil : state.filter.tags.map { $0.name.lowercased() },
                    statuses: state.filter.transactionStatuses.isEmpty ? nil : state.filter.transactionStatuses.map(\.rawValue),
                    participants: state.filter.participants.isEmpty ? nil : state.filter.participants.map(\.id),
                    date: date
                )

                let resolvedTags = try await allTagsTask
                var filter = state.filter
                filter.allCategories = allCategories
                filter.allTags = resolvedTags
                filter.allStatuses = TransactionStatus.allCases
                filter.allTransactions = try await allTransactions

                // Predictions are concurrent: each input is independent
                // and the PredictionCache actor serialises internally, so
                // a `withTaskGroup` reduces wall time on cold caches.
                var predictedTransactionsAmount: Double = .zero
                if await cache.isReady(user: user) {
                    let monthForPrediction = state.filter.startDate.timeIntervalSince1970.yearMonth
                    predictedTransactionsAmount = await withTaskGroup(of: Double.self) { group in
                        for budget in budgets {
                            let input = CashlyPredictionInput.tabularData(
                                .budgetValue(
                                    date: monthForPrediction,
                                    category: budget.category.name
                                )
                            )
                            group.addTask { [cache] in
                                let result = await cache.prediction(input: input, model: .budgetValue)
                                if case let .tabularRegression(value) = result { return value }
                                return .zero
                            }
                        }
                        var total: Double = .zero
                        for await value in group { total += value }
                        return total
                    }
                }

                let resolvedUsers = try await users
                let rawTransactions = try await transactions
                // J6: kind filter applies post-fetch since the
                // persistence query layer doesn't filter on
                // TransactionKind. Empty set means "show all kinds".
                let kindFilter = state.filter.kinds
                let resolvedTransactions = kindFilter.isEmpty
                    ? rawTransactions
                    : rawTransactions.filter { kindFilter.contains($0.kind) }
                send(.update(
                    filter: filter,
                    budgets: budgets,
                    categories: categories,
                    transactions: resolvedTransactions,
                    tags: resolvedTags,
                    users: resolvedUsers,
                    user: user,
                    predictedTransactionsAmount: predictedTransactionsAmount
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "Main", underlying: error.localizedDescription))))
            }
    }

    private func fetchPredictions(state: MainState) -> PrismEffect<MainAction> {
        .run { _ in
            _ = await cache.setup(user: state.user)
        }
    }

    private func removeTag(tag: Tag) -> PrismEffect<MainAction> {
        .run { send in
            do {
                guard let tag = try await tagUseCase.getTag(id: tag.id) else {
                    send(.error(.persistence(.notFound(entity: "Tag", id: tag.id))))
                    return
                }
                try await tagUseCase.removeTag(id: tag.id)
                send(.fetch)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Tag", underlying: error.localizedDescription))))
            }
        }
    }

    private func removeTransaction(transaction: CashlyDomain.Transaction) -> PrismEffect<MainAction> {
        .run { send in
            do {
                try await transactionUseCase.removeTransaction(id: transaction.id)
                send(.fetch)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }

    private func importCSV(url: URL, state: MainState) -> PrismEffect<MainAction> {
        let categories = state.categories
        let budgets = state.budgets
        let txUseCase = transactionUseCase
        return .run { send in
            // Security-scoped resource handling for documents picked
            // outside the app sandbox. Always release the claim on
            // exit regardless of success.
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            let source: String
            do {
                source = try String(contentsOf: url, encoding: .utf8)
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "CSV", underlying: error.localizedDescription))))
                return
            }
            let rows: [CashlyCSVImporter.TransactionRow]
            do {
                rows = try CashlyCSVImporter.transactions(source)
            } catch {
                send(.error(.domain(.invalidInput(field: "csv", reason: String(describing: error)))))
                return
            }

            var added = 0
            var skipped = 0
            for row in rows {
                // Resolve category via fuzzy match — handles
                // exporter labels that may not be exact equality.
                guard let category = CashlyFuzzyMatch.bestMatch(
                    for: row.categoryName,
                    in: categories,
                    key: { $0.name }
                ) else {
                    skipped += 1
                    continue
                }
                let budget = CashlyFuzzyMatch.bestMatch(
                    for: row.budgetSummary,
                    in: budgets.filter { $0.category.id == category.id },
                    key: { $0.summary }
                )
                let status = Self.parseStatus(row.status)
                do {
                    try await txUseCase.addTransaction(
                        id: UUID().uuidString,
                        participants: [],
                        budget: budget,
                        amount: row.amount,
                        date: row.date,
                        summary: row.summary,
                        status: status,
                        splitMode: nil,
                        splitValue: nil,
                        paymentsPlan: nil,
                        kind: .expense,
                        needsReview: false,
                        category: category
                    )
                    added += 1
                } catch {
                    skipped += 1
                }
            }
            send(.csvImportFinished(added: added, skipped: skipped))
            send(.fetch)
        }
    }

    /// K7c: builds the Watch payload from the freshly-loaded
    /// transactions + active user. Income / expense / net totals
    /// mirror the K4 Insights summary; recent list caps at 5 rows
    /// so the Watch context dictionary stays under WCSession's
    /// applicationContext size budget.
    static func snapshot(
        transactions: [CashlyDomain.Transaction],
        user: User?
    ) -> WatchSnapshot {
        let income = transactions.reduce(Double.zero) { partial, tx in
            tx.kind == .income ? partial + tx.amount : partial
        }
        let expense = transactions.reduce(Double.zero) { partial, tx in
            tx.contributesToExpenseTotals ? partial + tx.amount : partial
        }
        let recent = transactions
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { tx in
                WatchTransactionRow(
                    id: tx.id,
                    summary: tx.summary,
                    amount: tx.amount,
                    date: tx.date,
                    kindRaw: tx.kind.rawValue
                )
            }
        let code = UserDefaults.standard.string(forKey: "cashly.currencyCode") ?? "USD"
        return WatchSnapshot(
            userId: user?.id,
            income: income,
            expense: expense,
            net: income - expense,
            currencyCode: code,
            recent: Array(recent)
        )
    }

    private static func parseStatus(_ raw: String) -> TransactionStatus {
        let lowered = raw.lowercased()
        if lowered.contains("settled") { return .settled }
        if lowered.contains("canceled") { return .canceled }
        if lowered.contains("receive") { return .pendingToReceive }
        return .pendingToPay
    }

    private func reorderCategories(ids: [String]) -> PrismEffect<MainAction> {
        .run { send in
            do {
                try await categoryUseCase.reorderCategories(ids: ids)
                send(.fetch)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Category", underlying: error.localizedDescription))))
            }
        }
    }

    private func settleLoan(transaction tx: CashlyDomain.Transaction) -> PrismEffect<MainAction> {
        .run { send in
            do {
                // Re-add the same id with status .settled — addTransaction
                // is upsert-shaped so this updates in place.
                try await transactionUseCase.addTransaction(
                    id: tx.id,
                    participants: tx.participants,
                    budget: tx.budget,
                    amount: tx.amount,
                    date: tx.date,
                    summary: tx.summary,
                    status: .settled,
                    splitMode: tx.splitMode,
                    splitValue: tx.splitValue,
                    paymentsPlan: tx.paymentsPlan,
                    kind: tx.kind,
                    needsReview: tx.needsReview,
                    category: tx.category
                )
                send(.fetch)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }

    private func removeTransactions(transactions: Set<CashlyDomain.Transaction>) -> PrismEffect<MainAction> {
        .run { send in
            do {
                try await transactionUseCase.removeTransactions(ids: Set(transactions.map(\.id)))
                send(.fetch)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Transaction", underlying: error.localizedDescription))))
            }
        }
    }

    private func selectUser(state: MainState) -> PrismEffect<MainAction> {
        .run { send in
            do {
                guard let user = state.user else {
                    send(.error(.domain(.invalidInput(field: "user", reason: "No user selected."))))
                    return
                }
                try await userUseCase.selectUser(user: user)
                send(.fetch)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "User", underlying: error.localizedDescription))))
            }
        }
    }

    /// Computes spent ÷ budgeted per budget and fires a local
    /// notification when the ratio crosses `overshootThreshold`.
    /// Emits `.send(.stopLoading)` as the follow-up — the alert
    /// itself is scheduled on the platform side; `.update` doesn't
    /// need to wait for it.
    private func scheduleOvershootAlerts(
        budgets: [Budget],
        transactions: [CashlyDomain.Transaction]
    ) -> PrismEffect<MainAction> {
        let threshold = overshootThreshold
        let alerts = budgetAlerts
        let spentByBudget = Dictionary(
            grouping: transactions.compactMap { tx -> (String, Double)? in
                guard let budgetId = tx.budget?.id else { return nil }
                return (budgetId, tx.amount)
            },
            by: { $0.0 }
        ).mapValues { entries in
            entries.reduce(0.0) { partial, entry in partial + entry.1 }
        }
        // Snapshot value-types so the captured closure stays Sendable.
        let snapshots: [(id: String, summary: String, percentage: Int)] = budgets.compactMap { budget in
            guard budget.amount > 0,
                  let spent = spentByBudget[budget.id]
            else { return nil }
            let ratio = spent / budget.amount
            guard ratio >= threshold else { return nil }
            return (budget.id, budget.summary, Int((ratio * 100).rounded()))
        }
        return .merge(
            .run { [alerts] _ in
                for snap in snapshots {
                    await alerts.scheduleOvershootAlert(
                        budgetId: snap.id,
                        budgetSummary: snap.summary,
                        percentage: snap.percentage
                    )
                }
            },
            .send(.stopLoading)
        )
    }

    /// Wipe order matters — child entities first so the model
    /// container does not reject deletions on relationship refs.
    private func wipeAllData() -> PrismEffect<MainAction> {
        .run { send in
            do {
                try await transactionUseCase.removeTransactions()
                try await tagUseCase.removeTags()
                try await budgetUseCase.removeBudgets()
                try await categoryUseCase.removeCategories()
                try await userUseCase.removeUsers()
                await userPreferences.clearCurrentUserId()
                await budgetAlerts.cancelAll()
                await spotlight.clear()
                send(.fetch)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Data", underlying: error.localizedDescription))))
            }
        }
    }
}
