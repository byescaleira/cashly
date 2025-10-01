//
//  MainMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain

public actor MainMiddleware: CashlyMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase
    
    var budgetValuePrediction: CashlyPrediction?
    var categoryNamePrediction: CashlyPrediction?
    var tagValuePrediction: CashlyPrediction?
    
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
    
    public func run(state: MainState, action: MainAction) async -> AsyncStream<MainAction> {
        AsyncStream { continuation in
            Task {
                switch action {
                case .fetch:
                    await fetch(state: state, continuation: continuation)
                case .update:
                    continuation.yield(.stopLoading)
                case let .removeTag(tag):
                    await removeTag(tag: tag, continuation: continuation)
                case let .removeTransaction(transaction):
                    await removeTransaction(transaction: transaction, continuation: continuation)
                case let .removeTransactions(transactions):
                    await removeTransactions(transactions: transactions, continuation: continuation)
                case .selectUser:
                    await selectUser(state: state, continuation: continuation)
                case .fetchPredictions:
                    let _ = await setupPredictions(user: state.user)
                case .error, .stopLoading:
                    break
                }
            }
        }
    }
    
    func fetch(state: MainState, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            let user = try await userUseCase.getCurrentUser()
            let userFilter = user == nil ? nil : [user?.id ?? ""]
            
            let allCategories = try await categoryUseCase.getCategories(ids: nil, users: userFilter)
            let allBudgets = try await budgetUseCase.getBudgets(categories: allCategories.map(\.id), date: nil)
            async let allTags = tagUseCase.getTags(users: userFilter)
            async let allTransactions = transactionUseCase.getTransactions(
                budgets: allBudgets.map(\.id),
                tags: nil,
                statuses: nil,
                participants: nil,
                date: nil
            )
            
            let date: Date? = !state.filter.isFilteringByDate ? nil : state.filter.startDate
            
            async let tags = tagUseCase.getTags(users: userFilter)
            async let users = userUseCase.getUsers()
            
            let categories = try await categoryUseCase.getCategories(
                ids: state.filter.categories.isEmpty ? nil : state.filter.categories.map(\.id),
                users: userFilter
            )
            let budgets = try await budgetUseCase.getBudgets(
                categories: categories.map(\.id),
                date: date
            )
            
            async let transactions = transactionUseCase.getTransactions(
                budgets: budgets.map(\.id),
                tags: state.filter.tags.isEmpty ? nil : state.filter.tags.map { $0.name.lowercased() },
                statuses: state.filter.transactionStatuses.isEmpty ? nil : state.filter.transactionStatuses.map(\.rawValue),
                participants: state.filter.participants.isEmpty ? nil : state.filter.participants.map(\.id),
                date: date
            )
            
            var filter = state.filter
            filter.allCategories = allCategories
            filter.allTags = try await allTags
            filter.allStatuses = TransactionStatus.allCases
            filter.allTransactions = try await allTransactions
            
            var predictedTransactionsAmount: Double = .zero
            if await isSetupPredictions(user: user) {
                for budget in budgets {
                    let input = CashlyPredictionInput.tabularData(
                        .budgetValue(
                            date: state.filter.startDate.timeIntervalSince1970.yearMonth,
                            category: budget.category.name
                        )
                    )
                    let result = await prediction(input: input, model: .budgetValue)
                    switch result {
                    case .tabularRegression(let value): predictedTransactionsAmount += value
                    default: continue
                    }
                }
            }
            
            try await continuation.yield(
                .update(
                    filter: filter,
                    budgets: budgets,
                    categories: categories,
                    transactions: transactions,
                    tags: tags,
                    users: users,
                    user: user,
                    predictedTransactionsAmount: predictedTransactionsAmount
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func isSetupPredictions(user: User?) async -> Bool {
        guard let _ = budgetValuePrediction,
              let _ = categoryNamePrediction,
              let _ = tagValuePrediction
        else { return await setupPredictions(user: user) }
        return true
    }
    
    nonisolated func prediction(input: CashlyPredictionInput, model: CashlyIntelligence) async -> CashlyPredictionResult {
        guard let budgetValuePrediction = await budgetValuePrediction,
              let categoryNamePrediction = await categoryNamePrediction,
              let tagValuePrediction = await tagValuePrediction
        else { return .empty }
        switch model {
        case .budgetValue: return await budgetValuePrediction.regressionPrediction(from: input)
        case .categoryName: return await categoryNamePrediction.textPrediction(from: input)
        case .tagValue: return await tagValuePrediction.regressionPrediction(from: input)
        }
    }
    
    func setupPredictions(user: User?) async -> Bool {
        guard let user,
              let budgetValueModel = CashlyIntelligence.budgetValue.model(for: user),
              let categoryNameModel = CashlyIntelligence.categoryName.model(for: user),
              let tagValueModel = CashlyIntelligence.tagValue.model(for: user)
        else { return false }
        
        budgetValuePrediction = await CashlyPrediction(model: budgetValueModel)
        categoryNamePrediction = await CashlyPrediction(model: categoryNameModel)
        tagValuePrediction = await CashlyPrediction(model: tagValueModel)
        
        return true
    }
    
    func removeTag(tag: Tag, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            guard let tag = try await tagUseCase.getTag(id: tag.id) else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await tagUseCase.removeTag(id: tag.id)
            continuation.yield(.fetch)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeTransaction(transaction: CashlyDomain.Transaction, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await transactionUseCase.removeTransaction(id: transaction.id)
            continuation.yield(.fetch)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeTransactions(transactions: Set<CashlyDomain.Transaction>, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await transactionUseCase.removeTransactions(ids: Set(transactions.map(\.id)))
            continuation.yield(.fetch)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func selectUser(state: MainState, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            guard let user = state.user else {
                continuation.yield(.error(.onSave))
                return
            }
            try await userUseCase.selectUser(user: user)
            continuation.yield(.fetch)
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
}
