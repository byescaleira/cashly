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
                case let .removeUser(user):
                    await removeUser(user: user, continuation: continuation)
                case let .removeBudget(budget):
                    await removeBudget(budget: budget, continuation: continuation)
                case let .removeCategory(category):
                    await removeCategory(category: category, continuation: continuation)
                case let .removeTransaction(transaction):
                    await removeTransaction(transaction: transaction, continuation: continuation)
                case .selectUser:
                    await selectUser(state: state, continuation: continuation)
                case .error, .stopLoading:
                    break
                }
            }
        }
    }
    
    func fetch(state: MainState, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            let date: Date? = state.filter.isFilteringByDate ? nil : state.filter.startDate
            let budgets = try await budgetUseCase.getBudgets(
                categories: state.filter.categories.map(\.id),
                date: date
            )
            let user = try await userUseCase.getCurrentUser()
            let categories = try await categoryUseCase.getCategories()
            let transactions = try await transactionUseCase.getTransactions(
                budgets: budgets.map(\.id),
                tags: state.filter.tags.map(\.name),
                date: date
            )
            let tags = try await tagUseCase.getTags()
            let users = try await userUseCase.getUsers()
            continuation.yield(
                .update(
                    budgets: budgets,
                    categories: categories,
                    transactions: transactions,
                    tags: tags,
                    users: users,
                    user: user
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func removeTag(tag: Tag, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await tagUseCase.removeTag(id: tag.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeUser(user: User, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await userUseCase.removeUser(id: user.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeBudget(budget: Budget, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await budgetUseCase.removeBudget(id: budget.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeCategory(category: CashlyDomain.Category, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await categoryUseCase.removeCategory(id: category.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func removeTransaction(transaction: CashlyDomain.Transaction, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            try await transactionUseCase.removeTransaction(id: transaction.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
    
    func selectUser(state: MainState, continuation: AsyncStream<MainAction>.Continuation) async {
        do {
            guard let user = state.filter.user else {
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
