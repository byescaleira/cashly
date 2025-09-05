//
//  AddTransactionMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public actor AddTransactionMiddleware: CashlyMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase
    let participantUseCase: ParticipantUseCase
    
    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        tagUseCase: TagUseCase,
        userUseCase: UserUseCase,
        participantUseCase: ParticipantUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
        self.participantUseCase = participantUseCase
    }
    
    public func run(state: AddTransactionState, action: AddTransactionAction) async -> AsyncStream<AddTransactionAction> {
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
    
    func fetch(state: AddTransactionState, continuation: AsyncStream<AddTransactionAction>.Continuation) async {
        do {
            let transaction = try await transactionUseCase.getTransaction(id: state.id)
            let currentUser = try await userUseCase.getCurrentUser()
            let categories = try await categoryUseCase.getCategories(users: currentUser == nil ? nil : [currentUser!.id])
            let budgets = try await budgetUseCase.getBudgets(
                categories: categories.isEmpty ? nil : categories.map(\.id),
                date: state.date
            )
            
            continuation.yield(
                .update(
                    budgets: budgets,
                    id: transaction?.id ?? state.id,
                    participants: transaction?.participants ?? Array(state.participants),
                    budget: budgets.isEmpty ? nil : transaction?.budget ?? state.budget ?? budgets.first,
                    amount: transaction?.amount ?? state.amount,
                    date: transaction?.date.date ?? state.date,
                    summary: transaction?.summary ?? state.summary,
                    status: transaction?.status ?? state.status,
                    splitMode: transaction?.splitMode ?? state.splitMode,
                    splitValue: transaction?.splitValue ?? state.splitValue
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddTransactionState, continuation: AsyncStream<AddTransactionAction>.Continuation) async {
        do {
            guard let budget = state.budget,
                  state.amount > .zero,
                  state.summary.trimmingCharacters(in: .whitespacesAndNewlines).count > 3
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await transactionUseCase.addTransaction(
                id: state.id,
                participants: Array(state.participants),
                budget: budget,
                amount: state.amount,
                date: state.date.timeIntervalSince1970,
                summary: state.summary,
                status: state.status
            )
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddTransactionState, continuation: AsyncStream<AddTransactionAction>.Continuation) async {
        do {
            guard let _ = state.budget else {
                continuation.yield(.error(.onRemove))
                return
            }
            
            try await transactionUseCase.removeTransaction(id: state.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
