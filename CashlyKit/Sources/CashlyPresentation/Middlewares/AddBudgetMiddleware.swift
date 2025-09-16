//
//  AddBudgetMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public actor AddBudgetMiddleware: CashlyMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let userUseCase: UserUseCase
    
    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        userUseCase: UserUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.userUseCase = userUseCase
    }
    
    public func run(state: AddBudgetState, action: AddBudgetAction) async -> AsyncStream<AddBudgetAction> {
        AsyncStream { continuation in
            Task {
                switch action {
                case .fetch:
                    await fetch(state: state, continuation: continuation)
                case .save:
                    await save(state: state, continuation: continuation)
                case .remove:
                    await remove(state: state, continuation: continuation)
                case .update:
                    continuation.yield(.stopLoading)
                case .stopLoading, .saved, .error:
                    break
                }
            }
        }
    }
    
    func fetch(state: AddBudgetState, continuation: AsyncStream<AddBudgetAction>.Continuation) async {
        do {
            let budgets = try await budgetUseCase.getBudgets(
                categories: state.category == nil ? nil : [state.category?.id ?? ""],
                date: state.date
            )
            let fetchedBudget = try await budgetUseCase.getBudget(id: state.id)
            let budget = state.category != nil ? budgets.first : fetchedBudget
            let currentUser = try await userUseCase.getCurrentUser()
            let categories = try await categoryUseCase.getCategories(
                ids: nil,
                users: currentUser == nil ? nil : [currentUser?.id ?? ""]
            )
            continuation.yield(
                .update(
                    categories: categories,
                    id: budget?.id ?? UUID().uuidString,
                    amount: budget?.amount ?? .zero,
                    category: budget?.category ?? state.category ?? categories.first,
                    date: budget?.date ?? state.date.timeIntervalSince1970.yearMonth,
                    summary: budget?.summary ?? "",
                    isNew: budget == nil
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddBudgetState, continuation: AsyncStream<AddBudgetAction>.Continuation) async {
        do {
            guard let category = state.category,
                  state.amount > .zero,
                  state.summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await budgetUseCase.addBudget(
                id: state.id,
                amount: state.amount,
                category: category,
                date: state.date.timeIntervalSince1970.yearMonth,
                summary: state.summary
            )
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddBudgetState, continuation: AsyncStream<AddBudgetAction>.Continuation) async {
        do {
            let transaction = try await transactionUseCase.getTransactions(
                budgets: [state.id],
                tags: nil,
                statuses: nil,
                date: nil
            )
            
            guard let budget = try await budgetUseCase.getBudget(id: state.id),
                  transaction.isEmpty
            else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await budgetUseCase.removeBudget(id: budget.id)
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
