//
//  MainMiddleware.swift
//  CashlyKit
//

import CashlyDomain
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
    private let cache = PredictionCache()

    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        tagUseCase: TagUseCase,
        userUseCase: UserUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
    }

    public func run(state: MainState, action: MainAction) -> PrismEffect<MainAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .update: return .send(.stopLoading)
        case let .removeTag(tag): return removeTag(tag: tag)
        case let .removeTransaction(transaction): return removeTransaction(transaction: transaction)
        case let .removeTransactions(transactions): return removeTransactions(transactions: transactions)
        case .selectUser: return selectUser(state: state)
        case .fetchPredictions: return fetchPredictions(state: state)
        case .subscriptionUpdated, .error, .stopLoading, .replace: return .none
        }
    }

    private func fetch(state: MainState) -> PrismEffect<MainAction> {
        .run { send in
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
                let resolvedTransactions = try await transactions
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
}
