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
    
    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
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
                case .stopLoading, .error:
                    break
                }
            }
        }
    }
    
    func fetch(state: AddBudgetState, continuation: AsyncStream<AddBudgetAction>.Continuation) async {
        do {
            let budget = try await budgetUseCase.getBudget(id: state.id)
            let categories = try await categoryUseCase.getCategories()
            continuation.yield(
                .update(
                    categories: categories,
                    id: budget?.id ?? state.id,
                    amount: budget?.amount ?? state.amount,
                    category: budget?.category ?? state.category ?? categories.first,
                    date: budget?.date ?? state.date,
                    summary: budget?.summary ?? state.summary
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
                  !state.summary.isEmpty
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await budgetUseCase.addBudget(
                id: state.id,
                amount: state.amount,
                category: category,
                date: state.date,
                summary: state.summary
            )
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddBudgetState, continuation: AsyncStream<AddBudgetAction>.Continuation) async {
        do {
            let transaction = try await transactionUseCase.getTransactions(
                budget: state.id,
                category: state.category?.id,
                date: state.date
            )
            guard let budget = try await budgetUseCase.getBudget(id: state.id),
                  transaction.isEmpty
            else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await budgetUseCase.removeBudget(id: budget.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
