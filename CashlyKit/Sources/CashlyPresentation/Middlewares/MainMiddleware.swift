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
            let user = try await userUseCase.getCurrentUser()
            let categories = try await categoryUseCase.getCategories(
                ids: state.filter.categories.isEmpty ? nil : state.filter.categories.map(\.id),
                users: user == nil ? nil : [user?.id ?? ""]
            )
            let budgets = try await budgetUseCase.getBudgets(
                categories: categories.map(\.id),
                date: date
            )
            let transactions = try await transactionUseCase.getTransactions(
                budgets: budgets.map(\.id),
                tags: state.filter.tags.isEmpty ? nil : state.filter.tags.map(\.name),
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
